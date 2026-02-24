import Foundation

enum TourDefinitions {
    static let weekPlan: [TourStep] = [
        TourStep(
            anchorID: "day-card",
            title: "Tage belegen",
            text: "Tippe auf einen Tag, um ein Menu zuzuweisen. So planst du deine Woche.",
            position: .bottom
        ),
        TourStep(
            anchorID: "next-week-btn",
            title: "Woche wechseln",
            text: "Erstelle die nächste Woche oder wechsle zwischen bestehenden Wochen.",
            position: .bottom
        ),
        TourStep(
            anchorID: "date-picker-btn",
            title: "Datum wählen",
            text: "Springe direkt zu einer bestimmten Woche über den Kalender.",
            position: .bottom
        ),
        TourStep(
            anchorID: "context-switcher",
            title: "Kontext wechseln",
            text: "Wechsle hier zwischen deinem privaten Bereich und deinen Familien. Wochenpläne und Einkaufslisten werden pro Kontext getrennt.",
            position: .bottom
        ),
    ]

    static let menuPopup: [TourStep] = [
        TourStep(
            anchorID: "ingredient-chip",
            title: "Zutat zur Einkaufsliste",
            text: "Tippe auf eine Zutat, um sie direkt zur Einkaufsliste hinzuzufügen.",
            position: .bottom
        ),
        TourStep(
            anchorID: "menu-select",
            title: "Menu auswählen",
            text: "Tippe auf eine Menu-Karte, um dieses Menu dem Tag zuzuweisen.",
            position: .bottom
        ),
    ]

    static let menuManagement: [TourStep] = [
        TourStep(
            anchorID: "menu-form",
            title: "Menu erstellen",
            text: "Hier erstellst du neue Menus mit Titel, Zutaten, Notiz und Aufwand. Danach kannst du sie im Wochenplan einem Tag zuweisen.",
            position: .bottom
        ),
    ]

    static let shoppingList: [TourStep] = [
        TourStep(
            anchorID: "shopping-form",
            title: "Artikel hinzufügen",
            text: "Füge Artikel mit optionaler Mengenangabe zu deiner Einkaufsliste hinzu.",
            position: .bottom
        ),
        TourStep(
            anchorID: "shopping-items",
            title: "Einkaufsliste",
            text: "Tippe auf einen Artikel, um ihn als gekauft abzuhaken. Bearbeite oder lösche Einträge über die Icons.",
            position: .top
        ),
    ]

    static let familyManagement: [TourStep] = [
        TourStep(
            anchorID: "family-create",
            title: "Familie erstellen",
            text: "Erstelle eine Familie, um Wochenpläne und Einkaufslisten mit anderen zu teilen.",
            position: .bottom
        ),
        TourStep(
            anchorID: "context-info",
            title: "Kontext wechseln",
            text: "Wechsle oben in der Toolbar zwischen \"Privat\" und deinen Familien, um geteilte Daten zu sehen.",
            position: .bottom
        ),
    ]
}
