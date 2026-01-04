---
up: "[[初めてのGo言語]]"
related:
tags:
  - golang
aliases:
  - golang
created: 2025-12-21
updated: 2025-12-21
---
### 概要

Go言語（Golang）の **関数 (`func`)** は、プログラムの基本単位であり、他の言語と比べて **「シンプルだけど実用的な機能」** がいくつか詰め込まれています。

#### ==main==
**関数 `main`** とは、一言で言うと「プログラムの入り口（エントリーポイント）」です。

プログラムを実行したとき、コンピュータは「どこから読み始めればいいの？」と迷わないように、**「まずは `main` 関数を探して、そこから実行する」** というルールになっています。

これまでの文脈に合わせて、特に **Go言語における `main` 関数** の特徴とルールを解説します。

#### ==関数宣言==
- キーワードfunc
- 関数名
- **引数**：「,」が区切り文字で、`引数名：型名` の順番で書く
- **戻り値**：引数の終わりの `)` と `{` の間に書く

```go
// func 関数名(引数名 型, ...) 戻り値の型 { ... } 

func add(x int, y int) int {
	return x + y
}
```

### 詳細

##### ==名前付き引数とオプション引数==
「名前付き引数」と「オプション引数」はGo言語にはない機能。
実現しようとするには、構造体を使う必要がある

```go
type person struct {
	name string
	age  int
	pet  string
}

func MyFunc(person person) error {
	fmt.Println(person.name)
	fmt.Println(person.age)
	fmt.Println(person.pet)
	return nil
}

func main() {

	bob := person{
		name: "Bob",
		age:  20,
		pet:  "cat",
	}

	MyFunc(bob)
}
```

##### ==可変長引数とスライス==
可変長引数「...」は引数の最後である必要ある。
```go
func MyFunc(base int, vals ...int) []int {
	out := make([]int, 0, len(vals))
	for _, v := range vals {
		out = append(out, base+v)
	}
	return out
}

func main() {
	fmt.Println(MyFunc(1, 2, 3, 4, 5)) // [3 4 5 6 7]
	fmt.Println(MyFunc(10, 100, 200, 300, 400, 500)) // [110 120 130 140 150]
}
```

#####  ==複数の戻り値==
`,`で複数の戻り値を指定する
```go
func getName() (string, string, error) {
	return "Bob", "20", nil
}
```

##### ==戻り値の無視==
使わない値は、「_」（ブランク識別子）を使用する
```go
func calculator(a, b int) (int, int) {
    return a + b, a - b
}

func main() {
    // 2つ目の戻り値（引き算の結果）はいらないので _ で受ける
    sum, _ := calculator(10, 5)

    fmt.Println(sum) // 15
    // ここで 2つ目の値を使おうとするとエラーになる（存在しないため）
}
```

##### ==名前付き戻り値==
名前付き戻り値は、戻り値の型に対して追加でき、スコープは関数の中だけです
※シャドーイング変数には気をつけよう
```go
func divAndRemainder(num int, denom int) (result int, remainder int, err error) {
	result = num / denom
	remainder = num % denom
	return result, remainder, nil
}

func main() {
	result, remainder, err := divAndRemainder(10, 3)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(result, remainder) // 3 1
}
```

##### ==ブランクreturn==
**「`return` の後ろに何も書かないのに、値を返せる書き方」** で<mark style="background: #FF5582A6;">危険な書き方</mark>
- 関数 `add` が呼ばれた瞬間、戻り値用の変数 `sum` が自動的に作成（初期化）されます。
- 計算結果を `sum` に代入します。
- `return` だけで関数を抜けます。
- Goコンパイラが「あ、名前付き戻り値 `sum` があるから、今の `sum` の値を返せばいいんだな」と解釈してくれます。

```go
// 戻り値に名前 (sum) をつけておく！
func add(a, b int) (sum int) {
    sum = a + b // sum は自動で定義されているので代入するだけ
    return      // ← 空っぽ！ でも sum の中身が返される
}
```

##### ==シグネチャ==
**「その関数がどんな引数を受け取り、どんな値を返すか」という定義（型）**
2つの関数の引数にと戻り値の数が同じならば、両者のシグネチャが一致する
- 関数変数のデフォルト値：nil
- nilを実行するとパニックになる
```go

func f1(a string) int {
	return len(a)
}

// シグネチャ
var myFuncVar func(string) int
myFuncVar = f1
```

```go
func add(i int, j int) int {
	return i + j
}

func sub(i int, j int) int {
	return i - j
}

func mul(i int, j int) int {
	return i * j
}

func div(i int, j int) int {
	return i / j
}

func main() {
	var onMap = map[string]func(int, int) int{
		"add": add,
		"sub": sub,
		"mul": mul,
		"div": div,
	}
	fmt.Println(onMap["add"](1, 2))
}
```

##### ==関数型の宣言==
関数型を定義するのにも `type` が使えます
`type onFuncType func(int, int) int`

##### ==無名関数==
関数内部の関数とては、名前を持たない**無名関数**を使われます。
- 使用シーン
	- defer
	- ゴルーチン
```go

// 定義
f := func(j int) {
	fmt.Println("無名関数", j);
}

for i := 0; i < 5; i++ {
	f(i)
}

// 定義せずに実行も可能
for i := 0; i < 5; i++ {
	func(j int){
		fmt.Println("無名関数の中で", j)
	}(i)
}
```

##### ==クロージャ==
関数の内部で別の関数を宣言することができます。
メリットは、関数のスコープを制限できる。
関数fが何回も呼び出される時、パッケージレベルから隠して置ける
```go

a := 20
f := func() { //func()からが関数の定義。定義を変数fに代入
	fmt.Println(a) //外側で定義された変数にアクセス
}
f() // 20 
fmt.Println(a) // 30
```

##### ==関数引数==
ローカル変数を参照するクロージャを作成してそのクロージャを別の関数に渡すことで、**局所変数を外に持ち出せる**

```go
type Person struct {
	Name string
	Age  int
}

var people = []Person{
	{"John", 20},
	{"Jane", 30},
	{"Bob", 40},
}

func main() {
	fmt.Println(people)

	sort.Slice(people, func(i int, j int) bool {
		return people[i].Name < people[j].Name
	})
}
```

##### ==関数から関数を返す==
```go
func makeMult(base int) func(int) int {
	return func(num int) int {
		return base * num
	}
}
```

##### defer
ファイルやネットワークの一時的な「リソース」を作成することが、よくありますが、そういったリソースは後始末（クリーンアップ）が必要になります。
一言で言うと、**「後始末の予約機能」** 

`defer` と書かれた行は、その場では実行されず、関数を抜ける時まで待たされます。

- `defer` で指定できるのは一つの関数、メソッドあるいは、クロージャである。代表として「関数」と書く場合があります。この下の説明で、deferに関連して「関数」とだけ書いた場合には、メソッドやクロージャも含まれる
- 関数内で複数の関数を `defer` できる。クロージャはLIFO（後入れ先だし）で実行
- `defer` に指定された関数内のコードは `return` 文の後で実行される 先に述べた通り、`defer` 文の関数には引数を指定できます。指定された引数はすぐに評価され、その値は関数が実行されるまで保存されます。

```go
// 1. ここで予約する（まだ実行されない！）
defer fmt.Println("3. 後片付け（defer）")

// 2. 普通の処理が走る
fmt.Println("1. 開始")
fmt.Println("2. 処理中...")

// 3. 関数が終わる（returnする）直前に、予約していた処理が走る
1. 開始
2. 処理中...
3. 後片付け（defer）

```


**「`defer`」と「名前付き戻り値」の組み合わせ** は、Go言語における **裏ワザ的な超重要テクニック** です。
一言で言うと、**「`return` した後なのに、戻り値を書き換えることができる」** という挙動をします。

主に **「エラーの捕捉」** に使われます。

例えば、**「処理は成功したけど、最後にファイルを `Close` するときに失敗した」** というケース。 通常の方法では、`return nil`（成功）した後に `Close` のエラーを検知しても、戻り値を変更できません。
しかし、名前付き戻り値を使えば、**後出しでエラーを上書き**できます。

```go
func writeFile(filename string) (err error) {
    f, _ := os.Create(filename)
    
    // deferの中で、名前付き戻り値 err をチェック・書き換えできる
    defer func() {
        closeErr := f.Close()
        if err == nil {
            // 本処理が成功していても、Closeで失敗したらエラーとして返す
            err = closeErr
        }
    }()

    // 何か書き込み処理...
    
    return nil // 一旦「エラーなし」としてreturnする
}
```

##### Goは値渡し
Go言語における引数の渡し方は、**「すべて値渡し（Pass by Value）」** 
「参照渡し（Pass by Reference）」という機能はGo言語には存在しません。

ただ、**「ポインタを値として渡す」** ことで、実質的に参照渡しのような動きをさせたり、**「スライスやマップの仕様」** が参照渡しっぽく見えるため、混乱しやすいポイントです。

###### 1. 基本
関数に値を渡すと、**「その値のコピー（複製）」** が作られて関数に渡されます。 コピーの方をいくら書き換えても、**呼び出し元の元の変数は変化しません。**

```go
func change(num int) {
    num = 100 // コピーされた num を書き換えているだけ
    fmt.Println("関数内:", num) // 100
}

func main() {
    n := 10
    change(n)
    fmt.Println("main内:", n)   // 10 （変わっていない！）
}
```

###### 2. 応用：ポインタを渡す（擬似的な参照渡し）
元の変数を書き換えたい場合は、値そのものではなく、**「住所（メモリアドレス）」** を値として渡します。これがいわゆるポインタ渡しです。
```go
// *int は「int型の住所を受け取るよ」という意味
func change(num *int) {
    *num = 100 // 住所に行き、その中身を書き換える
}

func main() {
    n := 10
    // &n は「nの住所」
    change(&n)
    fmt.Println("main内:", n) // 100 （変わった！）
}
```

###### 3. 罠：スライスとマップ（参照型のような挙動）
ここが一番のハマりポイントです。 **スライスやマップを関数に渡して書き換えると、元の変数も変わります。**

「え？値渡しなんでしょ？コピーされるんじゃないの？」と思いますよね。

**理由:** スライスやマップの実体は、**「裏にあるデータへのポインタを持った小さな構造体」** だからです。 この「小さな構造体」自体はコピーされますが、コピーの中にある「ポインタ」は同じ場所を指しているため、中身が書き換わってしまいます。

```go
func modifySlice(s []int) {
    s[0] = 999 // 書き換わる！
}

func main() {
    data := []int{1, 2, 3}
    modifySlice(data)
    fmt.Println(data) // [999 2 3] （変わってしまった！）
}
```