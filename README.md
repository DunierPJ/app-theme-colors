# AppTheme

Theming claro/escuro (Material Design 3) para aplicações **Delphi FireMonkey (FMX)**.

A biblioteca gerencia o modo de tema (System/Light/Dark), segue automaticamente o tema do sistema operacional, pinta a **Status Bar** e **Navigation Bar** no Android, carrega paletas via **JSON** e aplica as cores nos componentes por meio de `TagString`, com suporte nativo aos controles FireMonkey e **Skia FMX**.

## Recursos

- **Três modos de tema** — `tmSystem`, `tmLight` e `tmDark`, controlados via `TThemeManager.Mode`.
- **Acompanha o tema do SO** — usa `IFMXSystemAppearanceService` e JNI nativa no Android (`TJConfiguration`) para detectar e reagir à troca de aparência do sistema.
- **Pintura de System Bars no Android** — altera automaticamente as cores e o tema dos ícones (Light/Dark) da **Status Bar** e **Navigation Bar**.
- **Múltiplas Tags no mesmo componente** — suporte a declarar várias regras no `TagString` separadas por ponto e vírgula `;` (ex.: `Fill:Surface; Stroke:Outline`).
- **Suporte Nativo ao Skia FMX** — suporte aos componentes Skia (`TSkLabel`, `TSkSvg`, `TSkAnimatedImage`).
- **Personalização via JSON** — permite importar/exportar paletas `TColorScheme` diretamente a partir de arquivos ou strings JSON (ex.: temas gerados no Material Theme Builder).
- **Aplicação automática e recursiva** — `TThemeApplier.ApplyToTree` percorre toda a árvore de componentes FMX e Skia.
- **Roles nomeadas (Material Design 3)** — cores definidas por papel semântico (`Primary`, `Surface`, `Outline`, `Error` etc.), com paletas `Light` e `Dark` prontas.
- **Recoloração segura de Bitmaps** — substitui a cor de bitmaps em `TImage` preservando o canal Alpha de transparência.

## Estrutura do projeto

| Unidade | Responsabilidade |
| --- | --- |
| `App.ThemeManager.pas` | Modo de tema (`TThemeMode`), detecção nativa do SO, controle das barras do Android (`ApplySystemBars`) e despacho de `TThemeChangedMessage`. |
| `App.ThemeApplier.pas` | Aplica as cores na árvore FMX/Skia a partir do `TagString` com suporte a múltiplas regras. |
| `App.ColorScheme.pas` | Record `TColorScheme` com as roles de cor e suporte a importação/exportação JSON (`FromJSON`, `LoadFromFile`, `ToJSON`). |
| `App.BitmapColor.pas` | Helper `TBitmapHelper` para cor dominante e recoloração preservando transparência (`ReplaceOpaqueColor`). |
| `App.ThemeMessage.pas` | Mensagens de notificação de troca de tema. |

## Requisitos

- Delphi com suporte a FireMonkey (FMX) — Delphi 10.4, 11, 12 Athens ou superior.
- Nenhuma dependência externa obrigatória.

## Instalação

1. Adicione a pasta `src` desta biblioteca ao *Search Path* do seu projeto:
   **Project ▸ Options ▸ Delphi Compiler ▸ Search Path**.
2. Inclua as unidades no seu código:

   ```pascal
   uses
     System.Messaging,
     App.ThemeManager, App.ThemeMessage, App.ThemeApplier, App.ColorScheme;
   ```

## Início rápido

### 1. Marque os componentes com tags

Defina o `TagString` dos componentes no formato `Tipo:Role`. Você pode usar múltiplas regras separadas por `;`:

```text
Fill:Primary                 → TShape / Skia (preenchimento)
Stroke:Outline               → TShape / Skia (contorno)
Font:OnSurface               → TText / TSkLabel (cor do texto)
Bitmap:Primary               → TImage / TSkSvg / TSkAnimatedImage (recolore imagem/SVG com a cor do tema)
Fill:Surface; Stroke:Outline → Aplica cor de fundo E cor de borda no mesmo componente
```

Exemplo no Form Designer:

| Componente | TagString |
| --- | --- |
| `TRectangle` (botão) | `Fill:Primary` |
| `TRectangle` (card) | `Fill:Surface; Stroke:Outline` |
| `TLabel` ou `TSkLabel` | `Font:OnSurface` |
| `TImage` ou `TSkSvg` | `Bitmap:Primary` |

### 2. Aplique o tema

```pascal
// Aplica as cores de acordo com o tema atual (e atualiza as barras do Android)
TThemeApplier.ApplyToTree(Self);
```

### 3. Troque o modo de tema

```pascal
TThemeManager.Mode := tmDark;   // tmLight, tmDark ou tmSystem
TThemeApplier.ApplyToTree(Self);
```

### 4. Carregar Temas Personalizados via JSON

Você pode carregar arquivos JSON gerados pelo **Material Theme Builder**:

```pascal
// Carrega temas customizados a partir de JSON
TThemeManager.LoadSchemesFromJSON(LightJsonString, DarkJsonString);
TThemeApplier.ApplyToTree(Self);
```

Exemplo de formato JSON suportado:

```json
{
  "Primary": "#0B9945",
  "OnPrimary": "#FFFFFF",
  "PrimaryContainer": "#A2E6BE",
  "Background": "#FBFCDC",
  "Surface": "#FBFCDC",
  "OnSurface": "#313332",
  "Outline": "#7D9988"
}
```

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

