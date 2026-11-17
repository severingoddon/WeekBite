def me(client, headers) -> dict:
    return client.get("/api/auth/me", headers=headers).json()


def member_emails(client, headers, family_id: int) -> list[str]:
    fam = next(f for f in client.get("/api/families", headers=headers).json() if f["id"] == family_id)
    return sorted(m["email"] for m in fam["members"])


def invite(client, headers, family_id: int, email: str):
    return client.post(f"/api/families/{family_id}/invite", json={"email": email}, headers=headers)


class TestFamilies:
    def test_creator_is_first_member(self, client, alice, user_id):
        fam = client.post("/api/families", json={"name": "Home"}, headers=alice).json()

        assert fam["name"] == "Home"
        assert fam["created_by"] == user_id(alice)
        assert [m["email"] for m in fam["members"]] == ["alice@example.com"]

    def test_only_creator_can_rename(self, client, alice, bob, family):
        fam = family(alice, bob)

        assert client.put(f"/api/families/{fam['id']}", json={"name": "Bobs"}, headers=bob).status_code == 403
        assert client.put(f"/api/families/{fam['id']}", json={"name": "Home"}, headers=alice).json()["name"] == "Home"

    def test_only_creator_can_delete(self, client, alice, bob, family):
        fam = family(alice, bob)

        assert client.delete(f"/api/families/{fam['id']}", headers=bob).status_code == 403
        assert client.delete(f"/api/families/{fam['id']}", headers=alice).status_code == 200
        assert client.get("/api/families", headers=bob).json() == []

    def test_deleting_active_family_resets_context(self, client, alice, bob, family, use_context):
        fam = family(alice, bob)
        use_context(bob, fam["id"])

        client.delete(f"/api/families/{fam['id']}", headers=alice)

        assert me(client, bob)["active_family_id"] is None


class TestInvites:
    def test_invite_accept_flow(self, client, alice, bob):
        fam = client.post("/api/families", json={"name": "Home"}, headers=alice).json()

        assert invite(client, alice, fam["id"], " Bob@Example.com ").status_code == 200
        pending = me(client, bob)["pending_invites"]
        assert [(i["family_name"], i["invited_by"]) for i in pending] == [("Home", "Alice")]

        client.post(f"/api/families/invites/{pending[0]['id']}/accept", headers=bob)

        assert member_emails(client, alice, fam["id"]) == ["alice@example.com", "bob@example.com"]
        assert me(client, bob)["pending_invites"] == []

    def test_decline(self, client, alice, bob):
        fam = client.post("/api/families", json={"name": "Home"}, headers=alice).json()
        invite(client, alice, fam["id"], "bob@example.com")
        invite_id = me(client, bob)["pending_invites"][0]["id"]

        assert client.post(f"/api/families/invites/{invite_id}/decline", headers=bob).status_code == 200
        assert me(client, bob)["pending_invites"] == []
        assert member_emails(client, alice, fam["id"]) == ["alice@example.com"]

    def test_invite_cannot_be_used_by_someone_else(self, client, alice, bob, carol):
        fam = client.post("/api/families", json={"name": "Home"}, headers=alice).json()
        invite(client, alice, fam["id"], "bob@example.com")
        invite_id = me(client, bob)["pending_invites"][0]["id"]

        assert client.post(f"/api/families/invites/{invite_id}/accept", headers=carol).status_code == 403
        assert client.post(f"/api/families/invites/{invite_id}/decline", headers=carol).status_code == 403

    def test_only_members_can_invite(self, client, alice, carol):
        fam = client.post("/api/families", json={"name": "Home"}, headers=alice).json()
        assert invite(client, carol, fam["id"], "carol@example.com").status_code == 403

    def test_duplicate_invites_and_existing_members_are_rejected(self, client, alice, bob, family):
        fam = family(alice, bob)

        assert invite(client, alice, fam["id"], "bob@example.com").status_code == 400
        assert invite(client, alice, fam["id"], "carol@example.com").status_code == 200
        assert invite(client, alice, fam["id"], "CAROL@example.com").status_code == 400


class TestMembership:
    def test_member_can_leave(self, client, alice, bob, family, user_id):
        fam = family(alice, bob)

        assert client.delete(f"/api/families/{fam['id']}/members/{user_id(bob)}", headers=bob).status_code == 200
        assert member_emails(client, alice, fam["id"]) == ["alice@example.com"]

    def test_creator_can_remove_members_and_their_context_is_reset(self, client, alice, bob, family, user_id, use_context):
        fam = family(alice, bob)
        use_context(bob, fam["id"])

        client.delete(f"/api/families/{fam['id']}/members/{user_id(bob)}", headers=alice)

        assert me(client, bob)["active_family_id"] is None
        assert client.get("/api/families", headers=bob).json() == []

    def test_members_cannot_remove_others(self, client, alice, bob, carol, family, user_id):
        fam = family(alice, bob, carol)

        assert client.delete(f"/api/families/{fam['id']}/members/{user_id(carol)}", headers=bob).status_code == 403
        assert client.delete(f"/api/families/{fam['id']}/members/{user_id(alice)}", headers=bob).status_code == 403

    def test_creator_cannot_leave(self, client, alice, family, user_id):
        fam = family(alice)
        assert client.delete(f"/api/families/{fam['id']}/members/{user_id(alice)}", headers=alice).status_code == 400


class TestContext:
    def test_switch_to_own_family_and_back(self, client, alice, bob, family, use_context):
        fam = family(alice, bob)

        use_context(bob, fam["id"])
        assert me(client, bob)["active_family_id"] == fam["id"]
        use_context(bob, None)
        assert me(client, bob)["active_family_id"] is None

    def test_cannot_switch_to_foreign_family(self, client, alice, carol, family):
        fam = family(alice)
        assert client.put("/api/context", json={"family_id": fam["id"]}, headers=carol).status_code == 403
