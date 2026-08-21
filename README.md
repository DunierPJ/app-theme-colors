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
| `App.ThemeInterfaces.pas` | Interfaces `IThemeManager`, `ISystemThemeDetector` e `ISystemBarsService`. |
| `App.SystemThemeDetector.pas` | Implementação de `ISystemThemeDetector` para detecção de tema do SO. |
| `App.SystemBarsService.pas` | Implementação de `ISystemBarsService` para estilização nativa de System Bars. |
| `App.ThemeManager.pas` | Gerenciador core (`TThemeManagerImpl`) e Facade estático (`TThemeManager`) para compatibilidade retroativa. |
| `App.ThemeApplier.pas` | Aplica as cores na árvore FMX a partir de `TagString`; cache de cor dominante. |
| `App.ColorScheme.pas` | Record `TColorScheme` com as roles de cor e as constantes `LightScheme` / `DarkScheme`. |
| `App.BitmapColor.pas` | Helper para descobrir a cor opaca dominante de um bitmap. |
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

Assine `TThemeChangedMessage` e repinte a UI. Isso cobre tanto a troca manual de `Mode` quanto a mudança de aparência do sistema operacional:

```pascal
procedure TForm1.FormCreate(Sender: TObject);
begin
  TMessageManager.DefaultManager.SubscribeToMessage(TThemeChangedMessage, ThemeChanged);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  TMessageManager.DefaultManager.Unsubscribe(TThemeChangedMessage, ThemeChanged);
end;

procedure TForm1.ThemeChanged(const Sender: TObject; const M: TMessage);
begin
  TThemeApplier.ApplyToTree(Self);
end;
```

## Convenção de Tags

O `TagString` segue o formato `Tipo:Role` (duas partes separadas por `:`). Partes inválidas ou nomes de role inexistentes no `TColorScheme` são ignorados.

| Tipo | Componente FMX | Propriedade alterada |
| --- | --- | --- |
| `Fill` | `TShape` | `Fill.Color` |
| `Stroke` | `TShape` | `Stroke.Color` |
| `Font` | `TText` | `Color` |
| `Bitmap` | `TImage` | `Bitmap.ReplaceOpaqueColor(cor dominante, cor do tema)` |

> **Dica:** para `TLabel`, use `Font:...` (o `TLabel` deriva de `TText`). Para `TCircle`, `TRoundRect`, `TPath` etc. (todos `TShape`), use `Fill:` ou `Stroke:`.

## Referência da API

### `App.ThemeManager.pas` — `TThemeManager` & `IThemeManager`

A biblioteca utiliza um design orientado a interfaces com suporte a Injeção de Dependência e um Facade estático para compatibilidade retroativa:

- **`IThemeManager`**: Interface principal que define operações de troca de modo, esquema ativo, e estilização de barras do sistema.
- **`ISystemThemeDetector`**: Interface para abstrair a verificação se o SO está em Dark Mode.
- **`ISystemBarsService`**: Interface para abstrair a estilização das barras de sistema (Status/Navigation Bars).
- **`TThemeManagerImpl`**: Implementação que aceita `ISystemThemeDetector` e `ISystemBarsService` via construtor (Injeção de Dependência), facilitando testes unitários ou customizações.
- **`TThemeManager`**: Facade estático mantido para 100% de compatibilidade retroativa.

```pascal
type
  TThemeMode = (tmSystem, tmLight, tmDark);
```

| Membro | Tipo | Descrição |
| --- | --- | --- |
| `Mode` | propriedade de classe | Modo atual do tema. Ao ser alterado, dispara `TThemeChangedMessage`. |
| `IsDark` | função de classe | Retorna `True` se o tema ativo é escuro (considera o modo do sistema quando `Mode = tmSystem`). |
| `Scheme` | função de classe | Retorna `LightScheme` ou `DarkScheme` (ou esquema customizado) conforme o tema ativo. |
| `SetCustomSchemes` | procedimento de classe | Define esquemas customizados para Light e Dark. |
| `LoadSchemesFromJSON` | procedimento de classe | Carrega e aplica esquemas a partir de strings JSON. |
| `ApplySystemBars` | procedimento de classe | Aplica o estilo do tema às barras de status e navegação do SO. |
| `Instance` | propriedade de classe | Acesso direto à instância `IThemeManager` subjacente. |

Internamente, `TThemeManagerImpl` assina `TSystemAppearanceChangedMessage` (FMX) e, quando o sistema muda de aparência, reenvia `TThemeChangedMessage` para que a UI repinte.

### `App.ThemeApplier.pas` — `TThemeApplier`

Classe estática que aplica o tema a uma árvore de componentes.

| Membro | Descrição |
| --- | --- |
| `ApplyToTree(ARoot: TFmxObject)` | Aplica as cores do tema atual a `ARoot` e a todos os descendentes, recursivamente. |
| `ColorByName(...)` | Resolve uma role pelo nome usando RTTI sobre os campos de `TColorScheme`. |
| `FDominantCache` | Cache `TDictionary<TBitmap, TAlphaColor>` da cor dominante de bitmaps já processados. |

### `App.BitmapColor.pas` — `TBitmapColorHelper`

| Membro | Descrição |
| --- | --- |
| `GetDominantOpaqueColor(ABitmap: TBitmap): TAlphaColor` | Retorna a cor 100% opaca (Alpha = 255) mais frequente no bitmap; fallback para preto se o bitmap estiver vazio. Usada como "cor de origem" do `ReplaceOpaqueColor`. |

### `App.ColorScheme.pas` — `TColorScheme`

Record com 17 roles de cor, e as constantes `LightScheme` e `DarkScheme`.

| Role | Light | Dark |
| --- | --- | --- |
| `Primary` | `$FF1B5E43` | `$FF4CAF7D` |
| `PrimaryContainer` | `$FF2E7D5B` | `$FF2E7D5B` |
| `OnPrimaryContainer` | `$FFFFFFFF` | `$FFFFFFFF` |
| `Secondary` | `$FF8A6D00` | `$FFD4B94B` |
| `Background` | `$FFF7F8F6` | `$FF121212` |
| `Surface` | `$FFFFFFFF` | `$FF1E1E1E` |
| `SurfaceVariant` | `$FFE5EAE6` | `$FF39403B` |
| `OnSurfaceVariant` | `$FF6B7280` | `$FFA0A5AC` |
| `Outline` | `$FF747E78` | `$FF8E9892` |
| `OutlineVariant` | `$FFCBD3CD` | `$FF444B46` |
| `Error` | `$FFB3261E` | `$FFF2B8B5` |
| `Success` | `$FF1B5E43` | `$FF4CAF7D` |
| `OnPrimary` | `$FFFFFFFF` | `$FF121212` |
| `OnSecondary` | `$FFFFFFFF` | `$FF121212` |
| `OnBackground` | `$FF121212` | `$FFFFFFFF` |
| `OnSurface` | `$FF121212` | `$FFFFFFFF` |
| `OnError` | `$FFFFFFFF` | `$FF601410` |

### `App.ThemeMessage.pas` — `TThemeChangedMessage`

```pascal
type
  TThemeChangedMessage = class(TMessage);
```

Mensagem disparada sempre que o tema muda (troca manual de `Mode` ou mudança de aparência do sistema). A UI deve assiná-la e repintar.

## Exemplos

### Botão de alternância claro/escuro

```pascal
procedure TForm1.BtnToggleThemeClick(Sender: TObject);
begin
  if TThemeManager.IsDark then
    TThemeManager.Mode := tmLight
  else
    TThemeManager.Mode := tmDark;
end;
```

### Lendo as cores do tema diretamente

```pascal
var
  Scheme: TColorScheme;
begin
  Scheme := TThemeManager.Scheme;
  PaintBox.Color := Scheme.Primary;
  Label1.Color  := Scheme.OnSurface;
end;
```

### Recolorindo um ícone de bitmap

Defina o `TagString` do `TImage` como `Bitmap:Primary`. Ao aplicar o tema, a cor dominante do bitmap é substituída pela cor `Primary`

=======

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).
