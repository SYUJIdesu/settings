---
up: "[[初めてのGo言語]]"
related:
tags:
  - golang
aliases:
  - golang
created: 2025-12-22
updated: 2025-12-22
---
### 概要

型、メソッド、インタフェースに対するGoのアプローチは、他の言語と大きく異なっている。
Goでは、継承ではなく、合成が推奨されます。
型は抽象型と具象型に分かれる

##### ==抽象型==
型が何をするものかを定義し、それをどのようにするかは規定しない。
つまり実装はしない
「インタフェース」を用いて表現される

##### ==具象型==
データの記憶のされ方を規定した上で、型に付随して定義される「メソッド」の実装を提供します
メモリ上に値を持つ具体的な型
例：数値型、string、構造体、スライス、マップ、チャネルなどが具象
※具象型には動的ディスパッチはない

##### ==基底型==
ユーザー定義型を含むすべての型は、その型のベースになる基底型を持つ

これはGo言語の仕様上の概念で、**「その型が元々は何から作られているか（ルーツ）」**を指します。 `type` キーワードを使って新しい型を作ったときに意識する必要があります。
- **特徴:** 異なる名前の型同士でも、**「基底型」が同じなら型変換（キャスト）が可能**です。
- **例:** `type MyInt int` と定義した場合、`MyInt` は新しい型ですが、基底型は `int` です。

例：
```go

//構造体リテラル
type Person struct {
	name string
	age int
}

//各基底型
type score int
type convert func(string)score
type scores map[string]score

```

### 詳細

#### ==型メソッドまたはメソッド==
ユーザーが定義した型に付随する関数を定義可能
`func` と関数名の間に「**レシーバー**」を追加
メソッドはパッケージレベルでしか定義できない
```go
type User struct {
	Name string
}

// レシーバ部分: (u User)
// 「この SayHello は User型 専用ですよ」という宣言
func (u User) SayHello() string {
	return "こんにちは、私は" + u.Name + "です"
}

func main() {
	user := User{Name: "悟空"}
	name := user.SayHello() // 呼び出し方: 変数名.メソッド名()
	fmt.Println(name)
}
```

#### ==関数とメソッドの比較==
関数が使えるとこは、メソッドも使える

| **特徴**       | **関数 (Function)** | **メソッド (Method)**             |
| ------------ | ----------------- | ----------------------------- |
| **定義の形**     | `func Name(...)`  | `func (r Receiver) Name(...)` |
| **呼び出し方**    | `Name()`          | `instance.Name()`             |
| **所属**       | 独立している（パッケージに属する） | **特定の型（構造体など）に属する**           |
| **インターフェース** | 満たすことができない        | **満たすことができる**                 |

#### ==ポイント型レシーバと値型レシーバ==
レシバーは2種類ある

|**特徴**|**値レシーバ (s MyStruct)**|**ポインタレシーバ (s *MyStruct)**|
|---|---|---|
|**イメージ**|**コピー（複製）** を渡す|**住所（アドレス）** を渡す|
|**元のデータの変更**|**できない** (コピーが変わるだけ)|**できる** (実体が書き換わる)|
|**パフォーマンス**|大きい構造体だと **遅い** (コピーするため)|常に **速い** (住所を渡すだけ)|
|**nil の扱い**|nil から呼び出すとパニックになる|**nil でも呼び出せる** (ガードが必要)|
|**よく使う場面**|`int` や `time.Time` のような不変な値、小さい構造体|状態を変更するsetter、大きい構造体|
#### ==メソッド値==
「特定のインスタンス（レシーバー）に結びついた状態のメソッド」を、変数として取り出したもののことです。
これを使うと、メソッドを「ただの関数」として持ち運んだり、他の関数に渡したりできるようになります。
```go
type Calculator struct {
    offset int
}

func (c Calculator) Add(a, b int) int {
    return a + b + c.offset
}

func main() {
    calc := Calculator{offset: 10}

    // これがメソッド値（calc というインスタンスが固定されている）
    f := calc.Add

    // 呼び出すときはレシーバーを指定する必要がない
    result := f(1, 2) // 1 + 2 + 10 = 13
}
```

#### ==メソッドの式==
よく混同されるものに「メソッド式」があります。これらは使い方が明確に異なります。

| **名称**    | **書き方**           | **特徴**                                        |
| --------- | ----------------- | --------------------------------------------- |
| **メソッド値** | `instance.Method` | **特定のインスタンス**に紐付いた関数になる。引数はメソッドの引数のみ。         |
| **メソッド式** | `Type.Method`     | **型**から関数を取り出す。第一引数に「どのインスタンスに適用するか」を渡す必要がある。 |
```go
// メソッド値 (Method Value)
f := calc.Add
f(1, 2) // 使いやすい

// メソッド式 (Method Expression)
g := Calculator.Add
g(calc, 1, 2) // 第一引数にインスタンスを渡す必要がある
```

##### ==関数とメソッドの使い分け==

##### 1. 基本的な違い（比較表）

| 特徴 | 関数 (Function) | メソッド (Method) |
| :--- | :--- | :--- |
| **定義** | `func Name(...)` | `func (r Receiver) Name(...)` |
| **呼び出し方** | `Name()` | `instance.Name()` |
| **依存性** | 独立している（汎用的） | 特定の型に紐付いている（振る舞い） |
| **インターフェース** | 満たすことができない | 満たすことができる |

##### 2. メソッドを選ぶべきケース
メソッドは、オブジェクト指向における「オブジェクトの振る舞い」を定義する際に使用します。

**内部状態（フィールド）を操作する場合**
構造体のデータを読み書きする処理はメソッドが適しています。
* **ポインタレシーバー `(t *T)`**: 状態を更新する場合（例：`User.UpdateEmail`）
* **値レシーバー `(t T)`**: 状態を参照して計算する場合（例：`Rect.Area`）

**インターフェースを実装する場合**
Goのポリモーフィズムはメソッドによって実現されます。
> 例：`fmt.Stringer` や `io.Reader` などの標準インターフェースを満たしたい場合は、必ずメソッドとして定義します。

**コードの可読性（メソッドチェーン）**
`a.Do().Next()` のように、操作を繋げて書くことで、処理の流れを左から右へ自然に読めるようにしたい場合に有効です。

##### 3. 関数を選ぶべきケース
関数は、特定のインスタンスに依存しない「独立したロジック」に適しています。

**コンストラクタ (NewXXX)**
Goでは慣習として、構造体の初期化は `New` で始まる関数で行います。
```go
func NewClient(timeout time.Duration) *Client {
    return &Client{Timeout: timeout}
}
```

#### ==型宣言と継承の違い==
このエラーは、Go言語の**型（Type）の不一致**によって発生します。

##### 1. エラーの原因
Go言語は非常に型に厳しい言語です。たとえ基底となるデータ型（Underlying Type）が同じ `int` であっても、`type` キーワードで新しく名前をつけた型は、**全く別の型**として扱われます。


- T1に代入できるリテラルや定数をT2に代入できる
- 型T1の変数等に関して使える演算子は型T2に対しても使うこともできる
```go
type Score int
type HighScore int

func main() {
    var s Score = 100
    var hs HighScore

    // ここでエラー発生！
    // s は "Score" 型であり、"HighScore" 型ではないため代入できない
    hs = s 
}
```

#### ==型は実行可能なドキュメント==
型はドキュメントであり、型はコードが表現する概念に名前を与え、コードが扱うべきデータを説明します。
コードを読む人にとって、メソッドの引数がint型であるよりPercentage型である方が意味がはっきりします、正しくない引数を指定してメソッドを呼び出してしまうことも少なくなります。

#### ==iotaと列挙型==
Goには列挙型の概念の代わりに、iota型がある
iotaを使う場合は、<mark style="background: #D2B3FFA6;">内部的な参照のみ</mark>
徐々に増加する値を一連の定数に割り当てることができます
0から順番に代入される

```go
// 型を定義
type MailCategory int // メールの分類

// 取りうる値の集合を定義
const (
	Uncategorized MailCategory = iota // 未分類
	Personal
	Spam
	Social
)

// iotaの仕様
const (
	Field1 = 0
	Field2 = 1 + iota // constの2行目なので1
	Field3 = 20 // 明確に値が指定されるとその値になる
	Field4 // 値の指定がないと直前の値と同じになる
	Field5 = iota // iotaは値の指定がない場合にのみ連番になる 4
	Field6 = iota // 5
	Field7 // 6 直前がiotaなので連番
)
```

#### ==埋め込みによる合成==
Goには継承がなく、「合成」と「昇格」が組み込まれており、これを使用したコードの再利用を推奨している

- **フィールドの昇格**: `m.Employee.Name` だけでなく、`m.Name` と直接書けるようになる。
- **メソッドの昇格**: `m.Employee.Describe()` だけでなく、`m.Describe()` と直接呼び出せるようになる。

```go
type Employee struct {
	Name string
	Age  int
}

type Manager struct {
	Employee //埋め込みフィールド Name Age が Manager に直接追加される
	Reports  []Employee
}

func (e Employee) Describe() string {
	return e.Name + " is " + strconv.Itoa(e.Age) + " years old."
}

func (m Manager) findReports() []Employee {
	// 修正後：型名を省略してスッキリ
	employees := []Employee{
		{"Alice", 25}, // これで OK
		{"Bob", 30},
	}
	return employees
}

func main() {
	m := Manager{
		Employee: Employee{"John", 40},
		Reports:  []Employee{},
	}
	fmt.Println(m.Age)        // 40
	fmt.Println(m.Describe()) // John is 40 years old.
	fmt.Println(m.Employee)   // {John 40}
	fmt.Println(m.Reports)    // []
	m.Reports = m.findReports()
	fmt.Println(m.Reports) // [{Alice 25} {Bob 30}]

}
```

##### 同名のフィールドの場合には前の方が隠される
```go
typ Inner struct {
	X int
}

type Outer struct {
	Inner
	X int
}

o := Outer{
	Inner: {
		X: 10
	},
	X: 20,
}

o.X        // 20
o.inner X  //10

```