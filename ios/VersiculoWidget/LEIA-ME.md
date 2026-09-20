# Como integrar esta pasta no Xcode

Os arquivos `.swift` desta pasta (Provider, VersiculoWidget,
VersiculoWidgetEntryView, VersiculoWidgetBundle) e o `.entitlements` são o
CÓDIGO do widget — mas o *target* do Xcode (o projeto que compila esse
código como uma extensão) só pode ser criado pela própria interface do
Xcode, não por arquivo de texto. Passo a passo:

1. Depois de rodar `flutter create .` (ver README.md na raiz) e
   `pod install`, abra `ios/Runner.xcworkspace` no Xcode.
2. **File > New > Target… > Widget Extension**. Nome: `VersiculoWidget`.
   Desmarque "Include Configuration Intent" (usamos StaticConfiguration,
   ver comentário em VersiculoWidget.swift sobre trocar para
   AppIntentConfiguration no futuro).
3. O Xcode vai criar uma pasta `VersiculoWidget/` com arquivos de exemplo
   (`VersiculoWidget.swift`, `VersiculoWidgetBundle.swift`, um
   `Info.plist` e um `.entitlements` gerados por ele). **Apague os `.swift`
   de exemplo que o Xcode criou** e arraste os 4 arquivos `.swift` desta
   pasta para dentro do target `VersiculoWidget` recém-criado (marcando
   "Copy items if needed" e o target membership correto).
4. Para o `Info.plist`: o Xcode moderno geralmente gera as chaves de versão
   automaticamente via build settings (`GENERATE_INFOPLIST_FILE`). Não
   troque o Info.plist inteiro do Xcode pelo `Info.plist` desta pasta —
   apenas copie a entrada `NSExtension` (e `CFBundleDisplayName`, se
   quiser) para dentro do que o Xcode já gerou.
5. Para o `.entitlements`: substitua o conteúdo do `.entitlements` que o
   Xcode gerou para o target `VersiculoWidget` pelo conteúdo de
   `VersiculoWidget.entitlements` desta pasta (ou simplesmente adicione a
   capability "App Groups" pela aba Signing & Capabilities e marque/crie o
   grupo `group.com.versiculonatela.app`).
6. Repita a capability "App Groups" no target `Runner` também, usando
   `ios/Runner/Runner.entitlements` desta entrega como referência — o
   MESMO grupo precisa estar marcado nos dois targets, senão
   `UserDefaults(suiteName:)` retorna nil dos dois lados.
7. Criar o App Group de verdade (`group.com.versiculonatela.app`) exige uma
   conta Apple Developer paga, feita em developer.apple.com > Certificates,
   Identifiers & Profiles > App Groups.
8. Rode no simulador/aparelho, depois adicione o widget manualmente
   (toque e segure a tela inicial > "+" > Versículo na Tela) para testar
   os três tamanhos, e nos Widgets da Lock Screen (toque e segure a tela
   de bloqueio > Personalizar) para testar os accessory widgets.

Nenhum desses passos pode ser substituído por mais código — são
configurações do projeto Xcode em si.
