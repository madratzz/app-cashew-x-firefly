#!/usr/bin/env python3
"""Probe plan assumptions on a disposable Firefly III 6.6.2 installation."""

import argparse
import datetime as dt
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid


class UnexpectedStatus(Exception):
    def __init__(self, status):
        self.status = status


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Probe:
    def __init__(self, base, token):
        url = urllib.parse.urlsplit(base)
        loopback = url.scheme == "http" and url.hostname in {"localhost", "127.0.0.1"}
        if ((url.scheme != "https" and not loopback) or not url.hostname
                or "@" in url.netloc or "?" in base or "#" in base):
            raise ValueError("Invalid URL")
        path = url.path.rstrip("/")
        for suffix in ("/api/v1", "/api"):
            if path.endswith(suffix):
                path = path[:-len(suffix)]
                break
        self.base = url._replace(path=path + "/api/v1").geturl()
        self.token = token
        self.opener = urllib.request.build_opener(NoRedirect())
        self.cleanup = []
        self.prefix = f"cashew-probe-{uuid.uuid4().hex[:12]}"

    def request(self, method, path, body=None, query=None, *, token=None):
        target = self.base + path
        if query:
            target += "?" + urllib.parse.urlencode(query)
        headers = {
            "Authorization": f"Bearer {self.token if token is None else token}",
            "Accept": "application/vnd.api+json",
            "X-Trace-Id": str(uuid.uuid4()),
        }
        data = None
        if body is not None:
            headers["Content-Type"] = "application/json"
            data = json.dumps(body).encode()
        request = urllib.request.Request(target, data, headers, method=method)
        try:
            with self.opener.open(request, timeout=30) as response:
                payload = response.read()
        except urllib.error.HTTPError as error:
            error.close()
            raise UnexpectedStatus(error.code) from None
        return json.loads(payload) if payload else {}

    def create(self, path, body):
        item = self.request("POST", path, body)["data"]
        self.cleanup.append(f"{path}/{urllib.parse.quote(str(item['id']), safe='')}")
        return item

    def remove_fixtures(self):
        success = True
        for path in reversed(self.cleanup):
            try:
                self.request("DELETE", path)
            except UnexpectedStatus as error:
                success &= error.status == 404
            except Exception:
                success = False
        return success

    def account(self, kind):
        body = {"name": f"{self.prefix}-{kind}", "type": kind, "notes": self.prefix}
        if kind == "asset":
            body["account_role"] = "defaultAsset"
        return self.create("/accounts", body)

    def transaction(self, split, *, rules=False):
        return self.create("/transactions", {
            "group_title": self.prefix,
            "apply_rules": rules,
            "fire_webhooks": False,
            "transactions": [split],
        })

    def check(self, label, operation):
        try:
            print(f"{label}: {operation()}")
            return True
        except UnexpectedStatus as error:
            print(f"{label}: unverified (HTTP {error.status})")
        except Exception:
            print(f"{label}: unverified (fixture, connection, or response failed)")
        return False


def split_of(resource):
    return resource["attributes"]["transactions"][0]


def search_updated(probe, transaction_id, transaction_path, split):
    probe.request("PUT", transaction_path, {
        "apply_rules": False,
        "fire_webhooks": False,
        "transactions": [{
            "transaction_journal_id": split["transaction_journal_id"],
            "description": probe.prefix + "-edited",
        }],
    })
    today = dt.datetime.now(dt.timezone.utc).date()
    def found(date):
        page = probe.request("GET", "/search/transactions", query={
            "query": f"updated_at_after:{date.isoformat()} description_is:{probe.prefix}-edited",
            "limit": 50,
        })
        return any(item["id"] == transaction_id for item in page["data"])
    after_yesterday = found(today - dt.timedelta(days=1))
    after_tomorrow = found(today + dt.timedelta(days=2))
    if after_yesterday and not after_tomorrow:
        return "supported for an edited transaction with an older transaction date"
    if not after_yesterday and not after_tomorrow:
        control = probe.request("GET", "/search/transactions", query={
            "query": f"description_is:{probe.prefix}-edited",
        })
        if not any(item["id"] == transaction_id for item in control["data"]):
            raise ValueError("Search control failed")
    return "unsupported in the positive/negative search checks"


def limit_above_fifty(probe):
    page = probe.request("GET", "/accounts", query={"page": 1, "limit": 100})
    per_page = int(page["meta"]["pagination"]["per_page"])
    if per_page > 50:
        return f"accepted (server reports per_page={per_page})"
    return f"capped (server reports per_page={per_page})"


def preserve_omitted_fields(probe, asset, asset_path, transaction_path, original):
    category = probe.create("/categories", {"name": probe.prefix, "notes": probe.prefix})
    retained = []
    for label, path, patch, field, expected in [
        ("category", probe.cleanup[-1], {"name": probe.prefix + "-renamed"}, "notes",
         category["attributes"]["notes"]),
        ("account", asset_path, {"name": probe.prefix + "-wallet"}, "notes",
         asset["attributes"]["notes"]),
        ("transaction", transaction_path,
         {"group_title": probe.prefix + "-retitled", "apply_rules": False,
          "fire_webhooks": False}, "transactions", original),
    ]:
        probe.request("PUT", path, patch)
        actual = probe.request("GET", path)["data"]["attributes"][field]
        if label == "transaction":
            actual = {key: actual[0].get(key) for key in expected} if actual else None
        if actual != expected:
            return f"omitted fields changed on {label}"
        retained.append(label)
    return "omitted fields retained in " + ", ".join(retained) + " checks; other resources unverified"


def rule_effects(probe, withdrawal):
    group = probe.create("/rule-groups", {"title": probe.prefix, "active": True})
    before = probe.prefix + "-rule-in"
    after = probe.prefix + "-rule-out"
    probe.create("/rules", {
        "title": probe.prefix,
        "rule_group_id": group["id"],
        "active": True,
        "strict": True,
        "trigger": "store-journal",
        "triggers": [{"type": "description_is", "value": before}],
        "actions": [{"type": "set_description", "value": after}],
    })
    created = probe.transaction({**withdrawal, "description": before}, rules=True)
    reread = probe.request("GET", probe.cleanup[-1])["data"]
    if split_of(reread)["description"] != after:
        raise ValueError("Rule effect was not observed")
    if split_of(created)["description"] != after:
        return "POST response preceded the observed rule effect"
    return "rule effect already present in the POST response for the fixture"


def piggy_bank(probe, asset):
    asset_id = str(asset["id"])
    fields = {
        "name": probe.prefix,
        "accounts": [{"account_id": asset_id, "current_amount": "0"}],
        "transaction_currency_code": asset["attributes"]["currency_code"],
        "target_amount": "10",
    }
    try:
        piggy = probe.create("/piggy-banks", fields)
    except UnexpectedStatus as error:
        if error.status not in (400, 422):
            raise
        piggy = probe.create("/piggy-banks", {**fields, "account_id": asset_id})
        variant = "accounts[] was rejected; sending both fields succeeded"
    else:
        variant = "accounts[] with no account_id was accepted"
    if not any(str(account.get("account_id", account.get("id"))) == asset_id
               for account in piggy["attributes"]["accounts"]):
        raise ValueError("Piggy bank account was not retained")
    return variant


def reconciliation(probe, asset_id, date):
    for side in ("source_id", "destination_id"):
        try:
            item = probe.transaction({
                "type": "reconciliation", "date": date, "amount": "0.01",
                "description": probe.prefix + "-reconciliation", side: asset_id,
            })
        except UnexpectedStatus as error:
            if error.status not in (400, 422):
                raise
        else:
            if split_of(item)["type"] == "reconciliation":
                return f"accepted with only the asset {side}"
            return "accepted but returned a different transaction type"
    return "rejected with either asset side given alone"


def mint_pat(probe, container, user_id):
    if not user_id.isdecimal():
        raise ValueError("Unexpected user ID")
    docker_env = {key: value for key, value in os.environ.items()
                  if key not in {"FIREFLY_BASE_URL", "FIREFLY_API_TOKEN"}}
    php = r"""<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
"""
    def run(code):
        return subprocess.run(
            ["docker", "exec", "-i", "-w", "/var/www/html", container, "php"],
            input=php + code, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, env=docker_env, check=True, timeout=30,
        ).stdout
    try:
        # The probe-generated credential exists only in memory and the pipe.
        token = run(f"echo FireflyIII\\User::findOrFail({user_id})->"
                    f"createToken('{probe.prefix}')->accessToken;").strip()
        if not token or any(char.isspace() for char in token):
            raise ValueError("Missing minted credential")
        user = probe.request("GET", "/about/user", token=token)["data"]
        if str(user["id"]) != user_id:
            raise ValueError("Minted credential resolved to a different user")
    finally:
        run(f"Laravel\\Passport\\Token::query()->where('user_id', {user_id})->"
            f"where('name', '{probe.prefix}')->update(['revoked' => true]);")
    return "minted a personal access token non-interactively, authenticated, and revoked it"


def run_checks(probe, container):
    about = probe.request("GET", "/about")["data"]
    if about["version"].lstrip("v") != "6.6.2":
        print("Probe stopped: the server must run Firefly III 6.6.2.")
        return False
    user_id = str(probe.request("GET", "/about/user")["data"]["id"])

    def transaction_checks():
        asset = probe.account("asset")
        asset_path = probe.cleanup[-1]
        expense = probe.account("expense")
        asset_id = str(asset["id"])
        old = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=180)
        withdrawal = {
            "type": "withdrawal", "date": old.isoformat(), "amount": "0.01",
            "description": probe.prefix, "source_id": asset_id,
            "destination_id": str(expense["id"]),
        }
        transaction = probe.transaction(withdrawal)
        transaction_path = probe.cleanup[-1]
        original = split_of(transaction)
        a1 = probe.check("A1", lambda: search_updated(
            probe, transaction["id"], transaction_path, original))
        stable = {key: original[key] for key in ("source_id", "destination_id", "amount")}
        a3 = probe.check("A3", lambda: preserve_omitted_fields(
            probe, asset, asset_path, transaction_path, stable))
        a4 = probe.check("A4", lambda: rule_effects(probe, withdrawal))
        a5 = probe.check("A5", lambda: piggy_bank(probe, asset))
        a6 = probe.check("A6", lambda: reconciliation(
            probe, asset_id, dt.datetime.now(dt.timezone.utc).isoformat()))
        return all((a1, a3, a4, a5, a6))

    a2 = probe.check("A2", lambda: limit_above_fifty(probe))
    # A failed shared fixture should still allow the independent A2 and A7 checks.
    try:
        data_checks = transaction_checks()
    except Exception:
        print("A1/A3/A4/A5/A6: unverified (failed to create shared fixtures)")
        data_checks = False
    a7 = True
    if container:
        a7 = probe.check("A7", lambda: mint_pat(probe, container, user_id))
    else:
        print("A7: unverified (no disposable Docker container supplied)")
    return all((a2, data_checks, a7))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--disposable", action="store_true",
                        help="confirm the supplied server may be modified")
    parser.add_argument("--container", help="Docker container for the A7 PAT check")
    args = parser.parse_args()
    base = os.environ.get("FIREFLY_BASE_URL")
    token = os.environ.get("FIREFLY_API_TOKEN")
    if not base or not token:
        print("Probe skipped: FIREFLY_BASE_URL and FIREFLY_API_TOKEN are required.")
        return 0
    if not args.disposable:
        parser.error("--disposable is required because the probe writes fixtures")
    probe = None
    success = False
    try:
        probe = Probe(base, token)
        success = run_checks(probe, args.container)
    except UnexpectedStatus as error:
        print(f"Probe stopped during preflight (HTTP {error.status}).")
    except Exception:
        print("Probe stopped during preflight (configuration, connection, or response failed).")
    finally:
        if probe is not None and not probe.remove_fixtures():
            print("Some fixtures could not be removed. Discard the test instance.")
            success = False
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
