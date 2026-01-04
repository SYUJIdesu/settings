---
up: "[[Clean Architecture 達人に学ぶソフトウェアの構造と設計]]"
related:
tags:
  - アーキテクチャ
  - SOLIDの原則
aliases:
  - SOLIDの原則
created: 2025-12-17
updated: 2025-12-17
---

#### SOLIDの原則

##### 目的
以下のような性質を持つ中間レベルのソフトウェア構造を作ること
- 変更に強いこと
- 理解しやすいこと
- コンポーネントの基盤として、多くのソフトウエアシステムで利用できること

##### ==SRP：単一責任の原則==

コンウェイの法則から導かれる当然の帰結。個々のモジュールを変更する理由がたった一つだけになるように、ソフトウェアシステムの構造がそれを使う組織の社会的構造に大きな影響を受けるようにする

**「モジュールは、たったひとつのアクターに対して責務を負うべきである」**
アクター：システムに変更を要求する人物、またはグループ


「凝集性のある」という言葉が単一責任の原則を匂わせる
凝集性が、一つのアクターに対する責務を負うコードをまとめるフォースとなる

- デプロイとかするときに辛いとこれを破ってるってパターンが多いと思う
    - 「違う案件のチームのデプロイが衝突した」ってことは、単一責任になってない
        - ( コードレベルかモジュールレベルかコンポーネントレベルかはおいといて )

下記とも関係がある
- コンポーネントレベル
	- 「閉鎖性共通の原則（CCP）」
- アーキテクチャレベル
	- 「アーキテクチャの境界」を作るための「変更の軸」と呼ばれる

```php

// データ構造（単なるデータ入れ物）
// メソッドは持たず、アクターへの依存がない
class EmployeeData
{
    public function __construct(
        public int $id,
        public string $name,
        public int $hours
    ) {}
}

// ------------------------------------------------
// クラス1: 給与計算の責任（CFO担当）
// ------------------------------------------------
class PayCalculator
{
    public function calculatePay(EmployeeData $employee): float
    {
        // 給与計算専用のロジック
        return $this->calculateRegularHours($employee) * 2000;
    }

    private function calculateRegularHours(EmployeeData $employee): int
    {
        // 給与計算用の労働時間算出ロジック
        return $employee->hours;
    }
}

// ------------------------------------------------
// クラス2: レポート出力の責任（COO担当）
// ------------------------------------------------
class HourReporter
{
    public function reportHours(EmployeeData $employee): string
    {
        // レポート専用のロジック
        return "Report for {$employee->name}: " . $this->calculateRegularHours($employee);
    }

    private function calculateRegularHours(EmployeeData $employee): int
    {
        // レポート用の労働時間算出ロジック
        // ※ PayCalculatorのものと名前は同じでも、互いに影響しない独立したメソッド
        return $employee->hours;
    }
}

// ------------------------------------------------
// クラス3: 永続化の責任（CTO担当）
// ------------------------------------------------
class EmployeeSaver
{
    public function save(EmployeeData $employee): void
    {
        // DB保存のロジック
        echo "Saving {$employee->name} to DB...";
    }
}

// ------------------------------------------------
// 【オプション】Facadeパターン
// 使う側（クライアント）がバラバラのクラスを意識しなくて済むようにまとめる
// ------------------------------------------------
class EmployeeFacade
{
    public function __construct(
        private EmployeeData $data,
        private PayCalculator $payCalculator,
        private HourReporter $hourReporter,
        private EmployeeSaver $employeeSaver
    ) {}

    public function calculatePay(): float
    {
        return $this->payCalculator->calculatePay($this->data);
    }

    public function reportHours(): string
    {
        return $this->hourReporter->reportHours($this->data);
    }

    public function save(): void
    {
        $this->employeeSaver->save($this->data);
    }
}


```



##### ==OCP：オープン・クローズドの原則==

ソフトウェアを変更しやすくするために、既存のコードを変更よりも新しいコードの追加によってシステムの振る舞いを変更できるように設計すべきである

**「ソフトウェアの構成要素は拡張に対しては開いていて、修正に対して閉じていなければならない」**

変更の影響を受けずにシステムを拡張しやすくすること
システムをコンポーネントに分割して、コンポーネントの依存関係を階層構造にする
上位レベルのコンポーネンが下位レベルのコンポーネントの変更の影響を受けないようにする

<mark style="background: #D2B3FFA6;">最も重要なテーマの一つは、「ビジネスロジック（Interactor）は、Web（UIやフレームワーク）から守られなければならない」</mark>

言い換えれば、ソフトウェアの振る舞いは、**既存の成果物を変更せずに拡張できるようにすべきである**

```php

// Output Boundary (出力の境界)
// Interactorはこのインターフェース越しにデータを渡すため、
// 具体的な表示形式（HTMLやJSON）を知る必要がありません。 
interface FinancialReportPresenterInterface { 
    public function present(array $financialData): void; 
}

// Interactor (アプリケーションサービス)
class GenerateFinancialReportInteractor
{
    private FinancialReportPresenterInterface $presenter;

    // 依存性の注入（DI）
    public function __construct(FinancialReportPresenterInterface $presenter)
    {
        $this->presenter = $presenter;
    }

    public function handle(): void
    {
        // 1. 重要なビジネスロジック（データの取得や計算）
        // 本来はEntityやRepositoryを使いますが、ここでは簡略化しています。
        $data = [
            'revenue' => 1000000,
            'cost'    => 600000,
            'profit'  => 400000, // 利益計算ロジック
            'date'    => date('Y-m-d'),
        ];

        // 2. 結果をプレゼンターに渡す
        // Interactorは「誰がどう表示するか」に関知しない。
        $this->presenter->present($data);
    }
}

// Presenter (表示層)
class WebHtmlPresenter implements FinancialReportPresenterInterface
{
    public function present(array $financialData): void
    {
        // データをHTMLに整形する（ViewModelの作成など）
        echo "<h1>財務レポート</h1>";
        echo "<p>売上: {$financialData['revenue']} 円</p>";
        echo "<p style='color:red;'>コスト: {$financialData['cost']} 円</p>";
        echo "<p style='font-weight:bold;'>利益: {$financialData['profit']} 円</p>";
    }
}

// Presenter (表示層)
class ApiJsonPresenter implements FinancialReportPresenterInterface
{
    public function present(array $financialData): void
    {
        // データをJSONに整形する
        header('Content-Type: application/json');
        echo json_encode($financialData);
    }
}

// --- シチュエーション1: Webページで表示したい場合 ---
$webPresenter = new WebHtmlPresenter();
$useCase = new GenerateFinancialReportInteractor($webPresenter);

// Interactorを実行
$useCase->handle(); 
// 出力: <h1>財務レポート</h1><p>売上...（HTML）


echo "\n\n----------------\n\n";


// --- シチュエーション2: もしAPIとして提供したくなったら？ ---
// Interactorのコードを一切変更することなく（Closed）、
// 新しいPresenterを差し込むだけで拡張（Open）できます。
$jsonPresenter = new ApiJsonPresenter();
$useCaseForApi = new GenerateFinancialReportInteractor($jsonPresenter);

$useCaseForApi->handle();
// 出力: {"revenue":1000000,"cost":600000...（JSON）

```


##### ==LSP：リスコフの置換原則==
Barabara Liskovが提唱した派生型の定義。1988年に誕生
交換可能なパーツを使ってソフトウェアシステムを構築するなら、個々のパーツが交換可能となるような契約に従う必要がある

親クラス（またはインターフェース）を使っている場所を、その子クラス（実装クラス）に置き換えてもプログラムが壊れないようにしなければならない

アーキテクチャレベルにも適用できる。むしろ適用する。少しでも違反すると特別な仕組みだらけになる

**「子クラスは、親クラスが交わした『約束（契約）』を破ってはならない」** というルールです。

##### ==ISP：インターフェイス分離の原則==
ソフトウェアを設計する際には、使っていないものへの依存を回避すべきだという原則

クライアント（利用する側）に、利用しないメソッドへの依存を強制してはならない

```php

// 役割ごとにインターフェースを分離する
interface Printer {
    public function print(Document $d);
}

interface Scanner {
    public function scan(Document $d);
}

interface Fax {
    public function fax(Document $d);
}

// 必要なインターフェースだけを実装（implements）する

// 古いプリンターは「印刷」だけ実装すればいい
class OldFashionedPrinter implements Printer
{
    public function print(Document $d) {
        // 印刷処理
    }
}

// 高機能複合機は、複数のインターフェースを実装すればいい
class MultiFunctionPrinter implements Printer, Scanner, Fax
{
    public function print(Document $d) { /* ... */ }
    public function scan(Document $d)  { /* ... */ }
    public function fax(Document $d)   { /* ... */ }
}

```

##### ==DIP：依存関係逆転の原則==

「ソースコードの依存関係が抽象だけを参照しているもの。それが最も柔軟なシステムである」

- 上位レベルのモジュール（ビジネスロジック）は、下位レベルのモジュール（詳細な実装）に依存してはならない。両方とも「抽象（インターフェース）」に依存すべきである
- 抽象は詳細に依存してはならない。詳細は抽象に依存すべきである

```php

// Step A: 抽象（インターフェース）を作る これはビジネスロジック側（高レベル）の持ち物として定義します。
interface UserRepositoryInterface
{
    public function save(string $user): void;
}

// Step B: ビジネスロジックを修正 MySQLDatabase という具体的な名前はコードから消え、UserRepositoryInterface だけを知っている状態にします。
class UserRegisterInteractor
{
    private UserRepositoryInterface $repository;

    // コンストラクタでインターフェースを受け取る（依存性の注入）
    public function __construct(UserRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function handle(string $user)
    {
        // 具体的に何（MySQL? CSV?）に保存されるかは知らないが、
        // saveメソッドがあることだけは保証されている。
        $this->repository->save($user);
    }
}

// Step C: 具体的な実装を作る これはデータベースアクセス層（低レベル）の持ち物として定義します。
class MySQLDatabase implements UserRepositoryInterface
{
    public function save(string $user): void
    {
        echo "MySQLに {$user} を保存しました。";
    }
}

// （おまけ）テスト用にファイル保存に変えることも簡単！
class FileDatabase implements UserRepositoryInterface
{
    public function save(string $user): void
    {
        echo "ファイルに {$user} を書き込みました。";
    }
}

// ここで「MySQLを使うぞ」と決める
$db = new MySQLDatabase();

// ロジックには、その部品を渡す
$useCase = new UserRegisterInteractor($db);
$useCase->handle("Tanaka");

```
