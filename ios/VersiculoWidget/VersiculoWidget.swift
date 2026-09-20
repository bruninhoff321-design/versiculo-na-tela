import SwiftUI
import WidgetKit

/// Widget de tela inicial E de tela de bloqueio (seções 3, 4 e 28 do
/// briefing). Usamos StaticConfiguration (sem parâmetros de usuário) para
/// máxima compatibilidade de versão do iOS; se no futuro quiserem permitir
/// configurar o tema direto no próprio widget (long-press > Editar Widget),
/// isso vira um AppIntentConfiguration (iOS 17+) — structure preparada
/// para essa troca sem mexer na Provider ou na View.
struct VersiculoWidget: Widget {
    let kind: String = "VersiculoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VersiculoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Versículo na Tela")
        .description("Mostra um versículo bíblico direto na sua tela.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,   // tela inicial (seção 3)
            .accessoryRectangular, .accessoryInline, .accessoryCircular, // tela de bloqueio (seção 4)
        ])
    }
}
