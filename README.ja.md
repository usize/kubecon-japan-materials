# Kubernetes上でセキュアなエージェントワークフローを構築する

KubeCon Japan 2026 での講演「エージェントAIシステムにおけるアイデンティティ、認可、ランタイムガードレール」のデモ資料です。

[![Built on Rossoctl](images/rossoctl.png)](https://github.com/rossoctl/rossoctl)

[Rossoctl](https://github.com/rossoctl/rossoctl) エージェントプラットフォーム上に構築されています。

## 前提条件

- `kind`、`kubectl`、`helm`（v3）
- `docker` または `podman`
- `make`、`python3`、`uv`
- ホスト上で [Ollama](https://ollama.com) が動作しており、`llama3.2:3b` がダウンロード済みであること

```bash
ollama pull llama3.2:3b
```

## デモの実行

1つのスクリプトでデモ全体をステップごとに進められます。Kind クラスタの作成、プラットフォームのインストール、各ステージの順次実行を行います。要所で Enter キー入力を待機するため、流れを追いながら進められます。

```bash
bash scripts/demo.sh
```

ステージ構成:

1. **プラットフォーム** — Kind クラスタを作成し、SPIRE、Keycloak、MCP Gateway、MLflow、Rossoctl UI をインストールします。
2. **ツールサーバー** — MCP ツールバックエンド（市場データ、取引、ニュース）をビルド・デプロイし、ゲートウェイに登録します。
3. **アイデンティティ** — SPIFFE アイデンティティを持つエージェントをデプロイし、信頼されていない Pod がリジェクトされることを確認します。
4. **ハッピーパス** — 認証を設定し、UI を通じた金融クエリのライブデモを行います。
5. **プロンプトインジェクション + MLflow ジャッジ** — ニュース機能を持つエージェントをデプロイし、プロンプトインジェクション攻撃を実演し、カスタム MLflow ジャッジでトレースを評価します。
6. **IBAC ガードレール** — 同じ攻撃を再実行し、IBAC サイドカープラグインによりリアルタイムでブロックされることを確認します。

既にクラスタが稼働中の場合、プラットフォームセットアップのスキップや特定のステージからの開始が可能です:

```bash
bash scripts/demo.sh --skip-platform
bash scripts/demo.sh --skip-platform --start-from 3
```

すべてを削除するには:

```bash
bash scripts/teardown.sh               # デモワークロードを削除
bash scripts/teardown.sh --destroy-cluster  # Kind クラスタも削除
```

## 講演の流れ

**パート1 — セキュアなベースラインの確立。** エージェントには堅牢なグローバルアイデンティティが必要です。SPIFFE/SPIRE による暗号学的ワークロードアイデンティティと Keycloak によるトークン交換を使用し、信頼ドメイン全体で mTLS による認可を実施します。MCP Gateway は単一の認証済みエンドポイントの背後にツールサーバーを集約します。

**パート2 — エージェント固有の障害モードの実演。** アイデンティティとアクセス制御は必要条件ですが十分条件ではありません。ニュース記事に隠されたプロンプトインジェクションがエージェントをだましてデータを外部送信させます。エージェントが適切なアイデンティティを持っているにもかかわらず、攻撃は成功します。MLflow が完全なトレースをキャプチャします。

**パート3 — ループを閉じる。** MLflow のカスタムジャッジを使用してエージェントの振る舞いを事後的にスコアリングし、記録されたトレースからインジェクションを検出します。次に、同じジャッジロジックをリアルタイムガードレール（IBAC サイドカープラグイン）として適用し、データがPodを離れる前に外部送信をブロックします。エージェントコードの変更は不要 — インフラストラクチャが処理します。

## プラットフォームソース

プラットフォームは [kagenti/kagenti](https://github.com/kagenti/kagenti) のフォークからインストールされます。MLflow スコアラージョブランナーの修正（[#1605](https://github.com/kagenti/kagenti/issues/1605)）が含まれています。`env.sh` は `thirdparty/kagenti` が存在しない場合、`usize/kagenti` の `fix/mlflow-scorer-job-runner-v2` ブランチから自動クローンします。
