---
title: '2025-10-20 MLエンドポイントのためのライブラリを雑に比較する'
date: 2025-10-20T23:00:49+09:00
tags: ["Machine Learning", "MLOps"]
draft: false
---

お仕事でリアルタイムのMLエンドポイントを立てる事がなく、知見があまりない。  
単純に、各フレームワークでの実行速度が気になったから雑に比較してみた。

## 雑なまとめ

Pythonを使う環境ならFastAPIを使えば問題ない。欲を言えば、onnxにモデルを変換しておくのが理想。  
モデルをonnxに変換できる かつ **Rustを利用できる環境** なら、Rustでエンドポイントを立てるとより高速な推論が期待できる。


## 比較する条件

### フレームワーク

- Python
  - [FastAPI](https://fastapi.tiangolo.com/)
  - [Flask](https://flask.palletsprojects.com/en/stable/)
- Rust([axum](https://docs.rs/axum/latest/axum/), [tokio](https://docs.rs/tokio/latest/tokio/))
  - [ort(onnx runtime)](https://docs.rs/ort/latest/ort/)
  - [tract(onnx runtime)](https://docs.rs/tract-ffi/latest/tract/)

**※ RustのコードはClaudeCodeに書いてもらいました**


### モデル

- PyTorch(2層のNN)
- LightGBM
- PyTorch ONNX(2層のNN)
- LightGBM ONNX


## タスク

[Titanic](https://www.kaggle.com/competitions/titanic/overview)の生存予測(2値分類)

学習コードは `notebooks/` にある。

### 特徴量

- Pclass(Int)
- Sex(String)
- Age(Int)
- SibSp(Int)
- Parch(Int)
- Fare(Float)


### 前処理

- Sex →  Label Encoding
- Age → Fill Null(median)
- Age → Standard Scaler
- Fare → Standard Scaler


## 結果

各フレームワークで実装したエンドポイントに1000回のリクエストを送信して、計測した結果を集計した。       
すべて、同じマシン上で実行・リクエストを行っている。


| Framework        | 平均推論時間 (ms)   |
| ---------------- | ------------- |
| **FastAPI**      | 約 **1.75 ms** |
| **Flask**        | 約 **2.0 ms**  |
| **ort (Rust)**   | 約 **0.47 ms** |
| **tract (Rust)** | 約 **0.46 ms** |


---

### 各フレームワークごとの結果

| Framework        | モデル             | Avg   | Min   | Max   | Total    | Variance |
| ---------------- | --------------- | ----- | ----- | ----- | -------- | ------- |
| **FastAPI**      | PyTorch         | 1.761 | 1.591 | 7.440 | 1760.629 | 0.043   |
|                  | LightGBM        | 1.758 | 1.548 | 3.142 | 1758.414 | 0.017   |
|                  | PyTorch (onnx)  | 1.542 | 1.400 | 2.534 | 1541.626 | 0.009   |
|                  | LightGBM (onnx) | 1.757 | 1.562 | 2.716 | 1757.161 | 0.010   |
| **Flask**        | PyTorch         | 2.013 | 1.836 | 6.441 | 2013.075 | 0.037   |
|                  | LightGBM        | 2.170 | 2.005 | 3.072 | 2169.753 | 0.009   |
|                  | PyTorch (onnx)  | 1.774 | 1.612 | 2.348 | 1773.535 | 0.008   |
|                  | LightGBM (onnx) | 1.990 | 1.798 | 3.943 | 1989.903 | 0.023   |
| **ort (Rust)**   | PyTorch (onnx)  | 0.426 | 0.402 | 0.804 | 425.580  | 0.001   |
|                  | LightGBM (onnx) | 0.599 | 0.533 | 0.917 | 598.631  | 0.000   |
| **tract (Rust)** | PyTorch (onnx)  | 0.428 | 0.403 | 0.693 | 427.609  | 0.000   |
|                  | LightGBM (onnx) | 0.510 | 0.488 | 0.764 | 510.188  | 0.000   |


---


### モデルごとの結果


| モデル                 | Framework    | Avg   | Min   | Max   | Total    | Variance |
| ------------------- | ------------ | ----- | ----- | ----- | -------- | -------- |
| **PyTorch**         | FastAPI      | 1.761 | 1.591 | 7.440 | 1760.629 | 0.043    |
|                     | Flask        | 2.013 | 1.836 | 6.441 | 2013.075 | 0.037    |
| **LightGBM**        | FastAPI      | 1.758 | 1.548 | 3.142 | 1758.414 | 0.017    |
|                     | Flask        | 2.170 | 2.005 | 3.072 | 2169.753 | 0.009    |
| **PyTorch (onnx)**  | FastAPI      | 1.542 | 1.400 | 2.534 | 1541.626 | 0.009    |
|                     | Flask        | 1.774 | 1.612 | 2.348 | 1773.535 | 0.008    |
|                     | ort (Rust)   | 0.426 | 0.402 | 0.804 | 425.580  | 0.001    |
|                     | tract (Rust) | 0.428 | 0.403 | 0.693 | 427.609  | 0.000    |
| **LightGBM (onnx)** | FastAPI      | 1.757 | 1.562 | 2.716 | 1757.161 | 0.010    |
|                     | Flask        | 1.990 | 1.798 | 3.943 | 1989.903 | 0.023    |
|                     | ort (Rust)   | 0.599 | 0.533 | 0.917 | 598.631  | 0.000    |
|                     | tract (Rust) | 0.510 | 0.488 | 0.764 | 510.188  | 0.000    |


## まとめ

Pythonでエンドポイントを立てるならFastAPIを選べば間違いない、特に学習したモデルをonnxに変換できるとベスト。

モデルをonnxに変換できる かつ **Rustを利用できる環境** なら、Rustでエンドポイントを立てるのを検討しても良いと思う。

