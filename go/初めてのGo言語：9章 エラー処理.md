---
up: "[[初めてのGo言語]]"
related:
tags:
  - golang
aliases:
  - golang
created: 2025-12-25
updated: 2025-12-25
---
### 概要

Goのエラー処理は関数から「error型」を戻すことによってエラー（例外）処理をします
Goのアプローチは「ソフトウェアエンジニアリングの原則」に基づいたものです

- 関数が期待通りに実行された場合はerrorにはnilが返される
- 何かがうまくいかない場合はerrror型の値が返される
- 呼び出し側では、「error」の戻り値を「nil」と比較することでチェックし、そのエラーを処理したり、独自のエラーをかえしたりする。

##### 基本
```go
func getError(i int) (int, error) {
	if i == 0 {
		// エラーを返す
		return 0, errors.New("i is 0")
	}
	return i, nil
}
func main() {
	i, err := getError(0)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(i)
}
```


##### エラーメッセージ
- 英語で書く場合は、大文字で始めない
- 語尾は句点や改行はおかない
- nilでないエラーを戻すなら、それぞれの型のゼロ値に設定する
- nil以外になっていないかのチェックでエラー判定

##### エラーを返す理由
- 例外がると、コードのパスが分岐するのでわかりにくい
- エラー処理の強制
	- エラーチェックし処理する
	- 「 `_` 」を使って、エラーの無視を明示する


### 詳細

#### ==単純なエラーの際の文字列の利用==
文字列を渡すことでエラーを生成する二つの方法
##### 1. erros.New
```go
func getError(i int) (int, error) {
	if i == 0 {
		// エラーを返す
		return 0, errors.New("i is 0")
	}
	return i, nil
}
```


##### 2. fmt.Errorf
フォーマット関連の「verb（%s, %d, %lなど）」を使うことができます

※Verb（書式指定子）とは、「値をどのような形式で表示するか」を指定するための命令（記号）のことです
```go
func getError(i int) (int, error) {
	if i == 0 {
		// エラーを返す
		return 0, fmt.Errorf("%dは偶数ではありません", i)
	}
	return i, nil
}
```

#### ==センチネルエラー==
「現在の状態には問題があり、処理を続行できないこと」を知らせるものがる。それが「センチネルエラー」

パッケージレベルの変数として宣言されます。
標準ライブラリの `io.EOF` や `sql.ErrNoRows` などが代表的です。
自分で定義する場合は、以下のようにパッケージのトップレベルで宣言します

- パブリックなAPIの一部
- 広報互換性いを持つ全リリースに関して動作保証する必要がある
- 標準ライブラリにあれば、それを使う
- 追加の情報が必要ない場合にユーザー定義でセンチネルエラーを使用

```go
import "errors" // これがセンチネルエラー（慣習として Err で始める）
var ErrUserNotFound = errors.New("user not found")

func FindUser(id int) (*User, error) {
    if id != 1 {
        // 定義しておいたエラー変数をそのまま返す
        return nil, ErrUserNotFound
    }
    return &User{ID: 1, Name: "John"}, nil
}
```

##### 1. 利点
- **文字列比較の問題:** メッセージが少し変わっただけで判定が壊れる（脆い）。
- **センチネルの利点:** 変数（メモリ上のアドレス）を比較するため、メッセージの内容に関わらず「その種類のエラーであること」を100%確実に判定できる。

##### 2. 使い分け

|**種類**|**使い時**|**判定方法**|
|---|---|---|
|**センチネルエラー**|「見つからない」「権限がない」など、呼び出し側が**判定して処理を分岐させたい**とき。|`errors.Is(err, TargetErr)`|
|**カスタムエラー型 (Struct)**|エラーに「エラーコード」や「リトライ間隔」など、**具体的なデータ**を持たせたいとき。|`errors.As(err, &target)`|

#### ==エラーと値==
「error」はインターフェースなので、付加的な情報を含む独自のエラーを定義可能
例：エラーステータスコードの追加

```go
const (
	Invalid  status = iota + 1 // 1
	Valid                      // 2
	NotFound                   // 3
)

type statusErr struct {
	status  status
	message string
}

func (e *statusErr) Error() string {
	return e.message
}

func Generator(status status) error {
	return &statusErr{status: status, message: "error"}
}
```

#### ==エラーのラップ==
エラーを保ったまま付加的な情報を追加することを、エラーを「ラップする」と言う
また、エラーが連続しているもののことを「エラーチェーン」と呼ぶ
エラーをラップする関数は「verbである %w」

標準ライブラリには一度ラップされたエラーを「アンラップ」するための関数も用意されている

##### `fmt.Errorf("... %w", err)` 
- **外側（皮）**: `"in fileCheck: "` という追加メッセージ
- **内側（実）**: `err`（例えば `os.Open` が出した「ファイルが見つからない」というエラー）

| **書式**   | **特徴**                       | **判定 (errors.Is)**    |
| -------- | ---------------------------- | --------------------- |
| **`%v`** | エラーを **「ただの文字列」** に変換して埋め込む。 | **不可能**（元のエラーの情報が消える） |
| **`%w`** | エラーの **「型や正体」** を保持したまま包む。   | **可能**（中のエラーを特定できる）   |


```go
func fileCheck(name string) error {
	f, err := os.Open(name)
	if err != nil {
		return fmt.Errorf("in fileCheck: %w", err)
	}
	f.Close()
	return nil
}

func main() {
	err := fileCheck("notFound.txt")
	if err != nil {
		fmt.Println(err)
		if wrappedErr := errors.Unwrap(err); wrappedErr != nil {
			fmt.Println(wrappedErr)
		}
	}
}

```

##### `errors.Unwrap(err)`
`errors.Unwrap(err)` は、`%w` でラップされたエラーから、**「中身（一つ前のエラー）」を取り出すための関数**です。

###### 1. 基本的な動き
```go
originalErr := errors.New("根本的な原因")
wrappedErr := fmt.Errorf("追加メッセージ: %w", originalErr)

// Unwrap 実行
unwrapped := errors.Unwrap(wrappedErr)

fmt.Println(unwrapped) // 出力: 根本的な原因
```

###### 2. `Unwrap`  の重要なルール

**1. 一枚ずつしか剥けない**
エラーが3重にラップされている場合、`errors.Unwrap` を1回実行しても取り出せるのは「2番目の皮」までです。一番奥の芯にたどり着くには、何度も繰り返す必要があります。

**2. ラップされていない場合は `nil` を返す**
`%v` でラップしたエラーや、そもそもラップしていないエラーに対して実行すると、中身を辿ることができないため `nil` が返ります。

**3. なぜ `Unwrap` を直接使う機会が少ないのか？**
実は、実務で `errors.Unwrap` を直接書くことはあまりありません。なぜなら、**`errors.Is` や `errors.As` が裏側で自動的に `Unwrap` を繰り返してくれるから**です。
- **`errors.Is(err, target)`**: `Unwrap` を繰り返しながら、一番奥まで含めて「指定したエラーがあるか？」をチェックしてくれる。
- **`errors.As(err, &target)`**: `Unwrap` を繰り返しながら、指定した「型」に一致するものがあるか探してくれる。

自分で `for` ループを回して皮を剥くよりも、これらの関数に任せる方が安全で楽です。

**4. `Unwrap` はどうやって動いているのか？**
`fmt.Errorf("... %w", err)` が作るエラー構造体は、内部で `Unwrap() error` というメソッドを持っています。
```go
// イメージ的な構造
type wrapError struct {
    msg string
    err error // これが中身
}

func (e *wrapError) Unwrap() error {
    return e.err // 中身を返す
}
```


#### ==複数のエラーのラップ==
複数のエラーを返したい場合は、`errors.Join` を使用する

```go
type Person struct {
	FirstName string
	LastName  string
	Age       int
}

func validation(p Person) error {
	var errs []error
	if len(p.FirstName) == 0 {
		errs = append(errs, errors.New("first name is required"))
	}
	if len(p.LastName) == 0 {
		errs = append(errs, errors.New("last name is required"))
	}
	if p.Age < 0 {
		errs = append(errs, errors.New("age must be positive"))
	}
	if len(errs) > 0 {
		return errors.Join(errs...)
	}
	return nil
}

func main() {
	p := Person{
		FirstName: "John",
		LastName:  "",
		Age:       30,
	}
	err := validation(p)
	if err != nil {
		panic(err)
	}
}
```

##### マージする場合
`fmt.Errorf` に `%w` を複数指定することで一つの文字列になります

```go
err1 := errors.New("first name is required")
err2 := errors.New("last name is required")
err3 := errors.New("age must be positive")
err4 := fmt.Errorf("validation failed: %w, validation failed: %w, validation failed: %w", err1, err2, err3)
```


#### ==IsとAs==
Goは下記問題をパッケージ 「erros」の「Is」と「As」を使用し解決する
###### エラーのラップの問題点
- センチネルエラーがラップされると 「 == 」を使ってチェックできない
- 型アサーションあるいは型swtichを使ってカスタマイうされたエラーにマッチすることもできなくなる

##### errors.Is
戻されたエラー、あるいはラップしたその他のエラーが特定のセンチネルエラーのインスタンスにマッチするならば、「 `erros.Is` 」を使います

###### 1. `errors.Is` がやっていること
`errors.Is(err, target)` を実行すると、Go は裏側で以下のような動きを自動で繰り返してくれます。
1. 「今持っている `err` は、探している `target` と同じか？」
2. 「違うなら、`err` を 1 枚めくって（`Unwrap` して）、中身をチェックしよう」
3. 「一致するものが見つかるか、中身がなくなるまで繰り返す」

このように、**「玉ねぎの皮を剥きながら芯を探してくれる」**のが `errors.Is` の強みです。

###### 2. 使い方

| **引数**       | **役割**                                                 |
| ------------ | ------------------------------------------------------ |
| **`err`**    | **検査対象のエラー**。関数から返ってきた、ラップされているかもしれない変数。               |
| **`target`** | **探しているエラー（見本）**。通常、パッケージレベルで定義された固定のエラー（センチネルエラー）。    |
| **戻り値**      | `err` の中身を辿って `target` が見つかれば `true`、見つからなければ `false`。 |
```go
func Is(err, target error) bool
```


###### 3. 実践的な使い方
```go
// 1. センチネルエラー（見張り役）を定義
var ErrConnectionRefused = errors.New("connection refused")

func connectDB() error {
    // 根本原因をさらに文脈で包んで返す
    return fmt.Errorf("database driver error: %w", ErrConnectionRefused)
}

func main() {
    err := connectDB()

    // 2. errors.Is で「犯人」を特定する
    // err が "%w" でラップされている限り、奥まで探しに行ってくれる
    if errors.Is(err, ErrConnectionRefused) {
        fmt.Println("❌ 接続エラーを確認しました。リトライを開始します...")
    } else if err != nil {
        fmt.Println("❓ 未知のエラー:", err)
    }
}
```

##### メソッドIs
`errors.Is` 関数は、単に「== での比較」や「`Unwrap` での遡り」をするだけではありません。対象のエラーが **`Is(error) bool` というメソッドを持っている場合、それを使って判定を行う** という仕様になっています。

###### 1. なぜ独自メソッド `Is` を作るのか？
通常、`errors.Is` は「全く同じインスタンス（変数）か」をチェックします。しかし、実務では **「インスタンスは違うけれど、意味的には同じエラーとして扱いたい」** という場面があります。
- **エラーコードで判定したい**: メッセージは毎回違うけれど、エラーコードが `404` なら「Not Found」として判定したい。
- **特定のグループにまとめたい**: 「タイムアウトエラー」と「接続拒否エラー」を、どちらも「ネットワーク系エラー」として判定したい。

###### 2. 独自メソッド `Is` の書き方
自分の構造体に `Is(target error) bool` を実装します。
```go
type MyError struct {
	Code    int
	Message string
}

// // Error() メソッドを実装する
func (e *MyError) Error() string {
	return e.Message
}

// これが「独自メソッド Is」！
func (e *MyError) Is(target error) bool {
	// 比較対象（target）を MyError 型に変換してみる
	t, ok := target.(*MyError)
	if !ok {
		return false
	}
	// インスタンスが別物でも、「Code」が同じなら「同じエラー」とみなす！
	return e.Code == t.Code
}

func main() {
	err1 := &MyError{Code: 404, Message: "ページがないよ"}
	err2 := &MyError{Code: 404, Message: "ファイルがないよ"}

	// 普通の比較 (==) なら false になる（ポインタのアドレスが違うため）
	fmt.Println(err1 == err2) // false

	// errors.Is なら、独自メソッド Is が呼ばれるので true になる！
	fmt.Println(errors.Is(err1, err2)) // true ✅
}
```

###### 4. `errors.Is` が裏側でやっていること
`errors.Is(err, target)` を呼び出したとき、Goは以下の優先順位でチェックを行っています。
1. **直接比較**: `err == target` か？
2. **独自メソッドの確認**: `err` が `Is(target error) bool` を持っているか？ 持っていればその結果を採用。
3. **Unwrapして再試行**: `Unwrap()` できるなら、中身を取り出して 1 に戻る。
この **2番目** のステップがあるおかげで、私たちは「何をもって『同じエラー』とみなすか」というルールを自分で決めることができるのです。

##### errors.As
「特定の職業（型）」を探して、その人の話を聞くための道具
「重なったエラーの中から、特定の構造体を取り出して、その中身（エラーコードなど）を触れるようにする」ための関数

###### 1. errors.Asの基本形と引数

| **引数**       | **役割**                                  |
| ------------ | --------------------------------------- |
| **`err`**    | **検査対象のエラー**。ラップされているかもしれない変数。          |
| **`target`** | **取り出し先の変数へのポインタ**。ここに「見つけたエラー」が代入されます。 |
| **戻り値**      | 指定した型が見つかれば `true`、見つからなければ `false`。    |
```go
func As(err error, target any) bool
```

#### ==`defer` を使ったエラーのラップ==
通常、関数内のいたるところで `if err != nil { return fmt.Errorf(...) }` と書くと、同じようなメッセージが何度も出てきてコードが汚くなりがちですが、`defer` を使うとそれを **1箇所に集約** できます。

deferは「`return` 命令が値をセットした直後、かつ、関数が物理的に終了する直前」に実行される

|**ステップ**|**動作**|**内容**|
|---|---|---|
|**Step 1**|**戻り値の確定**|戻り値用の変数（例：`err`）に、値を代入する。|
|**Step 2**|**`defer` の実行**|登録されていた `defer` 関数をすべて実行する。|
|**Step 3**|**関数の脱出**|呼び出し元（親関数）へ、変数の中身を持って戻る。|
```go

// 戻り値に名前をつけてdeferされた関数でerrを参照できるようにしておく必要がある
// 戻り値複数ある場合　戻り値を (_ string, err error)にする
func doSomething(val1 int, val2 string) (err error) {

	defer func() {

		if err != nil {
			// 低レベルのエラーをラップする
			err = fmt.Errorf("high level error: %w", err)
		}
	}()

	if val1 < 0 {
		return errors.New("val1 is negative")
	}
	if val2 == "" {
		return errors.New("val2 is empty")
	}

	return nil
}

func main() {
	err := doSomething(-1, "")
	if err != nil {
		fmt.Println(err)
	}
}

```

#### ==パニックとリカバー==
**`panic`（パニック）** と **`recover`（リカバー）** は **「予期せぬ致命的な事態」** に対処するための仕組みです。
Goにおいて、これらは「最終手段」として位置づけられています。

##### `panic`（パニック）とは何か？
`panic` は、プログラムが継続不可能な状態に陥ったときに発生する **「緊急停止ボタン」** です。
- **発生する原因:**
    - ランタイムによる自動発生：配列の範囲外アクセス、nilポインタへのアクセスなど。
    - 手動発生：`panic("致命的なエラー")` とコードに書いたとき。
- **挙動:**
    1. 通常のプログラム実行が **即座に中断** されます。
    2. ただし、その関数内で予約されていた **`defer` はすべて実行** されます。
    3. その後、呼び出し元（親関数）へパニックが伝染（伝播）し、最終的にプログラム全体がクラッシュして終了します。

##### `recover`（リカバー）とは何か？
`recover` は、発生したパニックを食い止め、**プログラムをクラッシュから救い出す（復旧させる）ための組み込み関数** です。
- **唯一の居場所:** `recover` は必ず **`defer` の中** で呼び出さなければなりません。
- **戻り値:**
    - パニックが起きていないとき：`nil` を返します。
    - パニックが起きたとき：`panic()` に渡された引数（エラーメッセージなど）を返し、**パニックを停止** させます。

```go
func safeFunction() (err error) {
    // 1. deferの中で recover を構えておく
    defer func() {
        if r := recover(); r != nil {
            // パニックを検知した！
            fmt.Printf("パニックから復旧しました: %v\n", r)
            // 2. 名前付き戻り値 err にエラーを代入して、
            // 「異常終了」ではなく「普通のエラー」として返す
            err = fmt.Errorf("recovered from panic: %v", r)
        }
    }()

    fmt.Println("処理開始")
    
    // 3. 意図的なパニック発生（例：配列の範囲外アクセスなど）
    nums := []int{1, 2}
    fmt.Println(nums[10]) // ここでランタイムパニックが発生！

    fmt.Println("この行は実行されません")
    return nil
}

func main() {
    err := safeFunction()
    if err != nil {
        fmt.Println("メイン関数でエラーとして捕捉:", err)
    }
    fmt.Println("プログラムは無事に継続しています。")
}
```

##### `panic` と `error` の使い分け
Goでは **「安易に `panic` を使わない」** というのが鉄の掟です。

|**特徴**|**error (値)**|**panic (停止)**|
|---|---|---|
|**想定シーン**|ファイルがない、入力ミス、通信失敗（日常的）|プログラミングミス、メモリ不足（致命的）|
|**処理方法**|`if err != nil` でその場で扱う|`defer` + `recover` で救出する|
|**思想**|**予測すべき事態** としてロジックに組み込む|**起きてはならない事態** として扱う|