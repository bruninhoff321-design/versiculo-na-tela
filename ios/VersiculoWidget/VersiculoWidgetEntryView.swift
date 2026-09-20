import SwiftUI
import WidgetKit

/// Paleta por tema visual — precisa espelhar AppTheme.widgetThemeColors
/// (Dart) e widgetThemeColors (Kotlin), para o widget parecer igual nas
/// duas plataformas.
func widgetThemeColors(_ theme: String) -> (Color, Color) {
    switch theme {
    case "escuro": return (Color(red: 0x1B/255, green: 0x1D/255, blue: 0x22/255),
                            Color(red: 0xF3/255, green: 0xEF/255, blue: 0xE4/255))
    case "papel": return (Color(red: 0xED/255, green: 0xE3/255, blue: 0xCC/255),
                           Color(red: 0x3A/255, green: 0x31/255, blue: 0x20/255))
    case "gradiente": return (Color(red: 0x3A/255, green: 0x2E/255, blue: 0x55/255),
                               Color(red: 0xFB/255, green: 0xF3/255, blue: 0xE7/255))
    case "elegante": return (Color(red: 0x12/255, green: 0x14/255, blue: 0x1A/255),
                              Color(red: 0xD9/255, green: 0xA8/255, blue: 0x57/255))
    case "ceu": return (Color(red: 0x2B/255, green: 0x3A/255, blue: 0x55/255),
                         Color(red: 0xFB/255, green: 0xFA/255, blue: 0xF6/255))
    default: return (Color(red: 0xF7/255, green: 0xF4/255, blue: 0xEC/255), // "claro"
                      Color(red: 0x20/255, green: 0x24/255, blue: 0x2B/255))
    }
}

struct VersiculoWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .accessoryRectangular, .accessoryInline, .accessoryCircular:
            // Widgets de Lock Screen (seção 4 do briefing, lado iPhone): o
            // próprio iOS controla a cor/tingimento aqui — não definimos
            // fundo nem cor de texto customizados, só o conteúdo. Tentar
            // forçar cores nesses estilos é ignorado pelo sistema (ou pior,
            // gera contraste ruim), então nem tentamos.
            lockScreenContent
                .containerBackground(for: .widget) { Color.clear }
        default:
            homeScreenContent
        }
    }

    @ViewBuilder
    private var lockScreenContent: some View {
        switch family {
        case .accessoryInline:
            Text(entry.verseReference)
        case .accessoryCircular:
            Text(entry.verseReference)
                .font(.system(size: 11, weight: .bold))
                .multilineTextAlignment(.center)
        default: // accessoryRectangular
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.verseText)
                    .font(.system(size: 12))
                    .lineLimit(3)
                Text(entry.verseReference)
                    .font(.system(size: 11, weight: .bold))
            }
        }
    }

    private var homeScreenContent: some View {
        let (bg, fg) = widgetThemeColors(entry.widgetTheme)

        return ZStack {
            bg
            VStack(spacing: 8) {
                Text("\u{201C}\(entry.verseText)\u{201D}")
                    .font(.system(size: fontSize, weight: .regular).italic())
                    .foregroundColor(fg)
                    .multilineTextAlignment(.center)
                    .lineLimit(lineLimit)
                    .minimumScaleFactor(0.75)
                Text(entry.verseReference)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(fg)
            }
            .padding()
        }
        // A partir do iOS 17 o WidgetKit exige um containerBackground
        // explícito (inclusive para widgets de Lock Screen); em versões
        // anteriores esse modifier é ignorado sem quebrar nada.
        .containerBackground(for: .widget) { bg }
    }

    private var fontSize: CGFloat {
        switch family {
        case .systemSmall: return 12
        case .systemLarge: return 17
        default: return 14
        }
    }

    private var lineLimit: Int {
        switch family {
        case .systemSmall: return 4
        case .systemLarge: return 10
        default: return 6
        }
    }
}
