# AppTheme

Theming claro/escuro (Material Design) para aplicações **Delphi FireMonkey**.

A biblioteca gerencia o modo de tema (System/Light/Dark), segue automaticamente o tema do sistema operacional e aplica as cores nos componentes por meio de `TagString`, sem precisar trocar `StyleBook` ou fazer associações manuais de cor.

## Recursos

- **Três modos de tema** — `tmSystem`, `tmLight` e `tmDark`, controlados via `TThemeManager.Mode`.
- **Acompanha o tema do SO** — usa `IFMXSystemAppearanceService` (Windows/macOS/iOS/Android) para detectar e reagir à troca de aparência do sistema.
- **Aplicação automática e recursiva** — `TThemeApplier.ApplyToTree` percorre toda a árvore de componentes e pinta shapes, textos e imagens a partir do `TagString`.
- **Roles nomeadas (Material Design 3)** — cores definidas por papel semântico (`Primary`, `Surface`, `Outline`, `Error` etc.), com paletas `Light` e `Dark` prontas.
- **Notificação via mensagens** — troca de tema dispara `TThemeChangedMessage`; a UI apenas assina a mensagem e repinta.
- **Recoloração de bitmaps** — detecta a cor dominante opaca de um `TImage` e a substitui pela cor do tema via `ReplaceOpaqueColor`.
- **Cache de cores dominantes** — evita reprocessar bitmaps repetidamente.

## Estrutura do projeto

| Unidade | Responsabilidade |
| --- | --- |
| `App.ThemeManager.pas` | Modo de tema (`TThemeMode`), detecção do tema do sistema e despacho de `TThemeChangedMessage`. |
| `App.ThemeApplier.pas` | Aplica as cores na árvore FMX a partir de `TagString`; cache de cor dominante. |
| `App.ColorScheme.pas` | Record `TColorScheme` com as roles de cor e as constantes `LightScheme` / `DarkScheme`. |
| `App.BitmapColor.pas` | Helper para descobrir a cor opaca dominante de um bitmap. |
| `App.ThemeMessage.pas` | Mensagens de notificação de troca de tema. |

## Requisitos

- Delphi com suporte a FireMonkey (FMX).
- Nenhuma dependência externa.

## Instalação

1. Adicione a pasta `src` desta biblioteca ao *Search Path* do seu projeto:
   **Project ▸ Options ▸ Delphi Compiler ▸ Search Path**.
   Ou, para usar em vários projetos, adicione em:
   **Tools ▸ Options ▸ Environment Variables ▸ Library ▸ Library Path**.
2. Inclua as unidades no seu código:

   ```pascal
   uses
     System.Messaging,
     App.ThemeManager, App.ThemeMessage, App.ThemeApplier, App.ColorScheme;
   ```

## Início rápido

### 1. Marque os componentes com tags

Defina o `TagString` de cada componente no formato `Tipo:Role`:

```text
Fill:Primary        → TShape  (preenchimento)
Stroke:Outline      → TShape  (contorno)
Font:OnSurface      → TText   (cor do texto)
Bitmap:Primary      → TImage  (recolore o bitmap com a cor do tema)
```

Exemplo no Form Designer:

| Componente | TagString |
| --- | --- |
| `TRectangle` (botão) | `Fill:Primary` |
| `TRectangle` (borda) | `Stroke:Outline` |
| `TLabel` | `Font:OnSurface` |
| `TImage` (ícone) | `Bitmap:Primary` |

### 2. Aplique o tema

```pascal
// Aplica as cores de acordo com o tema atual a partir da raiz (ex.: a Form)
TThemeApplier.ApplyToTree(Self);
```

### 3. Troque o modo de tema

```pascal
TThemeManager.Mode := tmDark;   // tmLight, tmDark ou tmSystem
TThemeApplier.ApplyToTree(Self);
```

### 4. Reaja a mudanças de tema automaticamente

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

### `App.ThemeManager.pas` — `TThemeManager`

Classe estática que concentra o estado do tema.

```pascal
type
  TThemeMode = (tmSystem, tmLight, tmDark);
```

| Membro | Tipo | Descrição |
| --- | --- | --- |
| `Mode` | propriedade de classe | Modo atual do tema. Ao ser alterado, dispara `TThemeChangedMessage`. |
| `IsDark` | função de classe | Retorna `True` se o tema ativo é escuro (considera o modo do sistema quando `Mode = tmSystem`). |
| `Scheme` | função de classe | Retorna `LightScheme` ou `DarkScheme` conforme o tema ativo. |

Internamente, `TThemeManager` assina `TMessageSystemAppearanceChanged` (FMX) e, quando o sistema muda de aparência, reenvia `TThemeChangedMessage` para que a UI repinte.

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

Defina o `TagString` do `TImage` como `Bitmap:Primary`. Ao aplicar o tema, a cor dominante do bitmap é substituída pela cor `Primary`:

```pascal
TThemeApplier.ApplyToTree(Self);
```

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).
