def titles(client, headers) -> list[str]:
    return [m["title"] for m in client.get("/api/menus", headers=headers).json()]


def test_create_and_read(client, alice, create_menu):
    menu = create_menu(alice, "Lasagne", ingredients=["Pasta", "Tomatoes"], note="Oven 200°C",
                       effort_min=60, link="https://example.com/lasagne")

    fetched = client.get(f"/api/menus/{menu['id']}", headers=alice).json()

    assert fetched == menu
    assert fetched["ingredients"] == ["Pasta", "Tomatoes"]
    assert fetched["effort_min"] == 60
    assert fetched["is_own"] is True


def test_defaults(client, alice, create_menu):
    menu = create_menu(alice, "Toast")
    assert (menu["note"], menu["effort_min"], menu["link"]) == ("", 20, "")


def test_list_is_sorted_by_title(client, alice, create_menu):
    for title in ["Risotto", "Curry", "Pizza"]:
        create_menu(alice, title)

    assert titles(client, alice) == ["Curry", "Pizza", "Risotto"]


def test_duplicate_title_is_rejected_per_user(client, alice, bob, create_menu):
    create_menu(alice, "Curry")

    assert client.post("/api/menus", json={"title": "Curry", "ingredients": []}, headers=alice).status_code == 400
    assert client.post("/api/menus", json={"title": "Curry", "ingredients": []}, headers=bob).status_code == 200


def test_update_replaces_ingredients(client, alice, create_menu):
    menu = create_menu(alice, "Curry", ingredients=["Rice", "Chicken"])

    response = client.put(
        f"/api/menus/{menu['id']}",
        json={"title": "Veggie Curry", "ingredients": ["Rice", "Tofu"], "note": "spicy"},
        headers=alice,
    )

    assert response.status_code == 200
    assert response.json()["title"] == "Veggie Curry"
    assert response.json()["ingredients"] == ["Rice", "Tofu"]
    assert response.json()["note"] == "spicy"


def test_delete(client, alice, create_menu):
    menu = create_menu(alice, "Curry")

    assert client.delete(f"/api/menus/{menu['id']}", headers=alice).status_code == 200
    assert titles(client, alice) == []


def test_menus_are_private_in_personal_context(client, alice, bob, create_menu):
    menu = create_menu(alice, "Secret recipe")

    assert titles(client, bob) == []
    assert client.get(f"/api/menus/{menu['id']}", headers=bob).status_code == 404
    assert client.put(f"/api/menus/{menu['id']}", json={"title": "Hacked", "ingredients": []}, headers=bob).status_code == 404
    assert client.delete(f"/api/menus/{menu['id']}", headers=bob).status_code == 404
    assert titles(client, alice) == ["Secret recipe"]


def test_family_context_shows_all_members_menus(client, alice, bob, carol, create_menu, family, use_context):
    create_menu(alice, "Alices dish")
    create_menu(bob, "Bobs dish")
    create_menu(carol, "Carols dish")
    fam = family(alice, bob)
    use_context(alice, fam["id"])

    menus = client.get("/api/menus", headers=alice).json()

    assert [(m["title"], m["is_own"], m["owner_name"]) for m in menus] == [
        ("Alices dish", True, None),
        ("Bobs dish", False, "Bob"),
    ]


def test_family_members_cannot_edit_each_others_menus(client, alice, bob, create_menu, family, use_context):
    menu = create_menu(bob, "Bobs dish")
    fam = family(alice, bob)
    use_context(alice, fam["id"])

    assert client.put(f"/api/menus/{menu['id']}", json={"title": "Hacked", "ingredients": []}, headers=alice).status_code == 404
    assert client.delete(f"/api/menus/{menu['id']}", headers=alice).status_code == 404
