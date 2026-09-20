import WidgetKit

/// Precisa ser o MESMO id configurado em
/// lib/data/widget_bridge/widget_sync_service.dart (iosAppGroupId) e nas
/// capacidades ("App Groups") dos dois targets no Xcode: Runner e
/// VersiculoWidget. Sem isso, UserDefaults(suiteName:) abaixo retorna nil
/// e o widget cai nos valores de exemplo (fallback).
let kAppGroupId = "group.com.versiculonatela.app"

struct VersiculoEntry: TimelineEntry {
    let date: Date
    let verseText: String
    let verseReference: String
    let widgetTheme: String
}

/// Lê o mesmo dado que o app Flutter grava via HomeWidget.saveWidgetData
/// (ver widget_sync_service.dart). O widget nunca decide qual versículo
/// mostrar — só lê o que o app já escolheu e gravou no App Group.
struct Provider: TimelineProvider {
    private let fallback = VersiculoEntry(
        date: Date(),
        verseText: "Vinde a mim, todos os que estais cansados e sobrecarregados, e eu vos aliviarei.",
        verseReference: "Mateus 11:28",
        widgetTheme: "claro"
    )

    func placeholder(in context: Context) -> VersiculoEntry {
        fallback
    }

    func getSnapshot(in context: Context, completion: @escaping (VersiculoEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VersiculoEntry>) -> Void) {
        let entry = readEntry()
        // O iOS controla quando o WidgetKit efetivamente pede a próxima
        // timeline (seção 28 do briefing: "o iOS controla quando timelines
        // de widgets podem ser atualizadas"). `.atEnd` pede ao sistema uma
        // nova timeline assim que ele julgar apropriado — normalmente logo
        // após o app chamar WidgetCenter.shared.reloadTimelines (disparado
        // pelo home_widget do lado Flutter a cada troca de versículo).
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func readEntry() -> VersiculoEntry {
        let defaults = UserDefaults(suiteName: kAppGroupId)
        return VersiculoEntry(
            date: Date(),
            verseText: defaults?.string(forKey: "verse_text") ?? fallback.verseText,
            verseReference: defaults?.string(forKey: "verse_reference") ?? fallback.verseReference,
            widgetTheme: defaults?.string(forKey: "widget_theme") ?? fallback.widgetTheme
        )
    }
}
