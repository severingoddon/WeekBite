from datetime import date, timedelta

import main

WEEKDAYS = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
THIS_MONDAY = date.today() - timedelta(days=date.today().weekday())
NEXT_MONDAY = THIS_MONDAY + timedelta(weeks=1)


def current_week(client, headers) -> dict:
    response = client.get("/api/week", headers=headers)
    assert response.status_code == 200, response.text
    return response.json()


def assign(client, headers, week_id: int, menu_id: int | None, day: str = "Montag"):
    return client.put(f"/api/week/{week_id}/{day}", json={"menu_id": menu_id}, headers=headers)


def menu_on(week: dict, day: str = "Montag") -> str | None:
    menu = next(d for d in week["days"] if d["day"] == day)["menu"]
    return menu["title"] if menu else None


class TestWeekLifecycle:
    def test_current_week_is_created_automatically(self, client, alice):
        week = current_week(client, alice)

        assert week["start_date"] == THIS_MONDAY.isoformat()
        assert [d["day"] for d in week["days"]] == WEEKDAYS
        assert all(d["menu"] is None for d in week["days"])
        assert current_week(client, alice)["id"] == week["id"]

    def test_any_date_resolves_to_its_monday(self, client, alice):
        week = current_week(client, alice)
        sunday = THIS_MONDAY + timedelta(days=6)

        assert client.get(f"/api/week?date_param={sunday}", headers=alice).json()["id"] == week["id"]

    def test_past_week_without_plan_is_not_created(self, client, alice):
        last_week = THIS_MONDAY - timedelta(weeks=1)
        assert client.get(f"/api/week?date_param={last_week}", headers=alice).status_code == 404

    def test_invalid_date_is_rejected(self, client, alice):
        assert client.get("/api/week?date_param=next-tuesday", headers=alice).status_code == 400

    def test_create_next_week(self, client, alice):
        assert client.get("/api/week/next-exists", headers=alice).json() == {
            "exists": False, "start_date": NEXT_MONDAY.isoformat(),
        }

        created = client.post("/api/week/next", headers=alice)

        assert created.status_code == 200
        assert created.json()["start_date"] == NEXT_MONDAY.isoformat()
        assert client.get("/api/week/next-exists", headers=alice).json()["exists"] is True
        assert client.post("/api/week/next", headers=alice).status_code == 409
        assert client.get(f"/api/week?date_param={NEXT_MONDAY}", headers=alice).json()["id"] == created.json()["id"]

    def test_reset_week(self, client, alice, create_menu):
        week = current_week(client, alice)
        menu = create_menu(alice, "Curry")
        assign(client, alice, week["id"], menu["id"], "Montag")
        assign(client, alice, week["id"], menu["id"], "Freitag")

        assert client.delete(f"/api/week/{week['id']}", headers=alice).status_code == 200
        assert all(d["menu"] is None for d in current_week(client, alice)["days"])


class TestAssignMenus:
    def test_assign_and_clear_own_menu(self, client, alice, create_menu):
        week = current_week(client, alice)
        menu = create_menu(alice, "Curry")

        assert assign(client, alice, week["id"], menu["id"], "Mittwoch").json()["menu"]["title"] == "Curry"
        assert menu_on(current_week(client, alice), "Mittwoch") == "Curry"

        assign(client, alice, week["id"], None, "Mittwoch")
        assert menu_on(current_week(client, alice), "Mittwoch") is None

    def test_unknown_day_is_rejected(self, client, alice, create_menu):
        week = current_week(client, alice)
        assert assign(client, alice, week["id"], None, "Funday").status_code == 404

    def test_foreign_menu_cannot_be_assigned(self, client, alice, bob, create_menu):
        """Regression: assigning someone else's menu leaked its content via GET /api/week."""
        week = current_week(client, alice)
        secret = create_menu(bob, "Bobs secret recipe", ingredients=["secret sauce"])

        assert assign(client, alice, week["id"], secret["id"]).status_code == 404
        assert menu_on(current_week(client, alice)) is None

    def test_deleted_menu_disappears_from_weeks(self, client, alice, bob, create_menu):
        """Deleting a menu must clear it from weeks, also if its id is reused later."""
        week = current_week(client, alice)
        menu = create_menu(alice, "Curry")
        assign(client, alice, week["id"], menu["id"])

        client.delete(f"/api/menus/{menu['id']}", headers=alice)
        create_menu(bob, "Bobs new dish")  # SQLite may reuse the freed id

        assert menu_on(current_week(client, alice)) is None


class TestFamilyWeeks:
    def test_private_and_family_weeks_are_separate(self, client, alice, bob, create_menu, family, use_context):
        fam = family(alice, bob)
        private = current_week(client, alice)
        use_context(alice, fam["id"])
        shared = current_week(client, alice)

        assert private["id"] != shared["id"]
        use_context(bob, fam["id"])
        assert current_week(client, bob)["id"] == shared["id"]

    def test_members_menus_can_be_assigned(self, client, alice, bob, create_menu, family, use_context):
        fam = family(alice, bob)
        bobs = create_menu(bob, "Bobs dish")
        use_context(alice, fam["id"])
        week = current_week(client, alice)

        assert assign(client, alice, week["id"], bobs["id"]).status_code == 200
        use_context(bob, fam["id"])
        assert menu_on(current_week(client, bob)) == "Bobs dish"

    def test_outsiders_menu_cannot_be_assigned(self, client, alice, bob, carol, create_menu, family, use_context):
        fam = family(alice, bob)
        carols = create_menu(carol, "Carols dish")
        use_context(alice, fam["id"])
        week = current_week(client, alice)

        assert assign(client, alice, week["id"], carols["id"]).status_code == 404

    def test_outsider_cannot_touch_family_or_private_week(self, client, alice, bob, carol, family, use_context):
        fam = family(alice, bob)
        private = current_week(client, alice)
        use_context(alice, fam["id"])
        shared = current_week(client, alice)

        for week in (private, shared):
            assert assign(client, carol, week["id"], None).status_code == 403
            assert client.delete(f"/api/week/{week['id']}", headers=carol).status_code == 403

    def test_deleting_family_removes_its_weeks(self, client, alice, bob, create_menu, family, use_context):
        """A new family that gets the freed id must not inherit the old family's weeks."""
        old = family(alice, name="Old")
        use_context(alice, old["id"])
        menu = create_menu(alice, "Old plan")
        assign(client, alice, current_week(client, alice)["id"], menu["id"])
        client.delete(f"/api/families/{old['id']}", headers=alice)

        new = family(bob, name="New")
        use_context(bob, new["id"])

        assert menu_on(current_week(client, bob)) is None


def test_weekday_names_match_backend():
    assert main.WEEKDAYS == WEEKDAYS
