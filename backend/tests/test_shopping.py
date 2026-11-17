def names(client, headers) -> list[str]:
    return [i["name"] for i in client.get("/api/shopping", headers=headers).json()]


def add(client, headers, name: str, quantity: str = ""):
    return client.post("/api/shopping", json={"name": name, "quantity": quantity}, headers=headers)


def test_add_and_list_in_insertion_order(client, alice):
    add(client, alice, "Milk", "1 l")
    add(client, alice, "Bread")

    items = client.get("/api/shopping", headers=alice).json()

    assert [(i["name"], i["quantity"], i["checked"]) for i in items] == [("Milk", "1 l", False), ("Bread", "", False)]


def test_duplicates_are_detected_case_insensitively(client, alice):
    first = add(client, alice, "Milk").json()
    second = add(client, alice, "  milk ").json()

    assert second["created"] is False
    assert second["id"] == first["id"]
    assert names(client, alice) == ["Milk"]


def test_update_toggle_delete(client, alice):
    item = add(client, alice, "Milk").json()

    assert client.put(f"/api/shopping/{item['id']}", json={"name": "Oat milk", "quantity": "2"}, headers=alice).json()["name"] == "Oat milk"
    assert client.patch(f"/api/shopping/{item['id']}/toggle", headers=alice).json()["checked"] is True
    assert client.patch(f"/api/shopping/{item['id']}/toggle", headers=alice).json()["checked"] is False
    assert client.delete(f"/api/shopping/{item['id']}", headers=alice).status_code == 200
    assert names(client, alice) == []


def test_items_of_others_are_protected(client, alice, bob):
    item = add(client, alice, "Milk").json()

    assert names(client, bob) == []
    assert client.put(f"/api/shopping/{item['id']}", json={"name": "Hacked"}, headers=bob).status_code == 403
    assert client.patch(f"/api/shopping/{item['id']}/toggle", headers=bob).status_code == 403
    assert client.delete(f"/api/shopping/{item['id']}", headers=bob).status_code == 403
    client.delete("/api/shopping", headers=bob)
    assert names(client, alice) == ["Milk"]


def test_family_list_is_shared_and_separate_from_private(client, alice, bob, family, use_context):
    fam = family(alice, bob)
    add(client, alice, "Private item")
    use_context(alice, fam["id"])
    add(client, alice, "Family item")
    use_context(bob, fam["id"])

    assert names(client, bob) == ["Family item"]
    item = client.get("/api/shopping", headers=bob).json()[0]
    assert client.patch(f"/api/shopping/{item['id']}/toggle", headers=bob).status_code == 200

    use_context(alice, None)
    assert names(client, alice) == ["Private item"]


def test_clear_only_affects_current_context(client, alice, bob, family, use_context):
    fam = family(alice, bob)
    add(client, alice, "Private item")
    use_context(alice, fam["id"])
    add(client, alice, "Family item")

    client.delete("/api/shopping", headers=alice)

    assert names(client, alice) == []
    use_context(alice, None)
    assert names(client, alice) == ["Private item"]


def test_deleting_family_removes_its_shopping_list(client, alice, bob, family, use_context):
    """A new family that gets the freed id must not inherit the old family's list."""
    old = family(alice, name="Old")
    use_context(alice, old["id"])
    add(client, alice, "Old item")
    client.delete(f"/api/families/{old['id']}", headers=alice)

    new = family(bob, name="New")
    use_context(bob, new["id"])

    assert names(client, bob) == []
