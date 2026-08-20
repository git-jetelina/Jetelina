"""
module: JAiE5ChatController

Author: Ono keiji

Description:
	AI inference for jetelina chatting
    using Microsoft Multilingual E5 Text Enbeddings

functions
    aiChatCommand() hear the user's command then apply it to the command list
    aiLearnCommand() learning in user's new word. adding a new word into HABITS_FILE
"""
module JAiE5ChatController

using Genie.Renderer.Json, Genie.Requests
using ONNXRunTime, CSV, DataFrames, LinearAlgebra, HuggingFaceTokenizers 
using Jetelina.JFiles, Jetelina.JMessage, Jetelina.JLog, Jetelina.JSession
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

export getAiChatCommand


const MODEL_PATH = getFileNameFromConfigPath(j_config.JC["onnxfile"])
const PREFIX = j_config.JC["onnxprefix"]
const CSV_PATH = getFileNameFromConfigPath(j_config.JC["chatcommandlist"])

#const MODEL_PATH = "model_quantized.onnx"
#const CSV_PATH = "master_commands.csv"
#const PREFIX = "jetelia_chat_message: "

# 最終形態の構造体
struct CommandEngine
    model::ONNXRunTime.InferenceSession
    tokenizer::HuggingFaceTokenizers.Tokenizer
    command_ids::Vector{String}
    master_embeddings::Matrix{Float32} 
end

"""
function get_embedding(model::ONNXRunTime.InferenceSession, tokenizer::HuggingFaceTokenizers.Tokenizer, text::String)

    map each word in a chat sentence to the closest vecor word in dictionary
# テキストを384次元のE5ベクトルに変換する関数（外部依存ゼロ・堅牢版）

# Arguments
- `model::ONNXRunTime.InferenceSession`: 
- `tokenizer::HuggingFaceTokenizers.Tokenizer`:
- `text::String`: chat input word
- return: {Any}: vector dimention(?)
"""
function get_embedding(model::ONNXRunTime.InferenceSession, tokenizer::HuggingFaceTokenizers.Tokenizer, text::String)
    # 1. 純Julia環境でのトークナイズ（数字ID化）
    result = HuggingFaceTokenizers.encode(tokenizer, text)
    ids = Int64.(result.ids)
    len = length(ids)
    
    # 2. ONNXが要求する3つのテンソルを生成
    input_ids = reshape(ids, 1, len)
    attention_mask = reshape(ones(Int64, len), 1, len)
    token_type_ids = reshape(zeros(Int64, len), 1, len)
    
    # 3. ONNX推論の実行
    outputs = model((
        input_ids = input_ids, 
        attention_mask = attention_mask,
        token_type_ids = token_type_ids
    ))
    
    # 4. 出力テンソルの正確なパース [トークン数, 384次元]
    raw_output = first(outputs)
    token_embeddings = reshape(raw_output, len, 384) 
    
    # 🌟 5. 自作・平均プーリング（Mean Pooling）
    # 外部ライブラリを一切使わず、縦方向に合計（sum）してトークン数（len）で割ります。
    # 名前空間の衝突が絶対に起きない、最軽量かつ堅牢な実装です。
    sum_vec = vec(sum(token_embeddings, dims=1))
    pooled_vec = Float32.(sum_vec ./ len)
    
    # 6. L2正規化（コサイン類似度を超高速な内積計算にするための必須処理）
    return pooled_vec / norm(pooled_vec)
end
"""
function init_engine()

    ready for embedding AI dictionary
# エンジンの初期化処理

# Arguments
- return {ANY}: dictionary data for AI chatting
"""
function init_engine()
    @info "=== 純Julia・爆速判定エンジンの初期化開始 ==="
    
    if !isfile(MODEL_PATH)
        error("ONNXモデル ($MODEL_PATH) が見つかりません。パスを確認してください。")
    end
    if !isfile(CSV_PATH)
        error("マスターCSV ($CSV_PATH) が見つかりません。")
    end
    
    # 1. ONNXモデルのロード
    @info "量子化済みONNXモデルをロード中: $MODEL_PATH"
    model = ONNXRunTime.load_inference(MODEL_PATH)
    
    # 2. トークナイザーのロード
    @info "HuggingFaceからトークナイザー設定を読込中..."
    tokenizer = HuggingFaceTokenizers.from_pretrained(Tokenizer, "intfloat/multilingual-e5-small")
    
    # 3. マスターCSVの読み込み
    @info "マスターCSVをロード中: $CSV_PATH"
#    df = CSV.read(CSV_PATH, DataFrame)
# 1. 一度そのままCSVをDataFrameとして読み込む（ヘッダーなし、列名自動付与の場合）
# ※もしヘッダーなしなら「header=false」にし、列名を指定すると扱いやすいです
df = CSV.read(CSV_PATH, DataFrame, header=false, stringtype=String)
rename!(df, [:command_id, :raw_phrases])

# 2. "raw_phrases" 列の文字列（"['a', 'b']"）をパースして「本物の配列」に変換
df.parsed_phrases = map(df.raw_phrases) do val
    clean_str = replace(val, r"[\[\]']" => "")
    return strip.(split(clean_str, ",")) # ここで1つのセルにVector{String}が入る
end

# 3. flatten機能で、配列の中身を展開して「1行1フレーズ」の縦長DataFrameに一撃変換！
df_expanded = flatten(df, :parsed_phrases)
    command_ids = Vector{String}(df.command_id)
    num_commands = length(command_ids)
prefix_phrases = "jetelina_chat_message: " .* df_expanded.parsed_phrases

    # 4. 起動時常駐化処理
    master_embeddings = Matrix{Float32}(undef, 384, num_commands)
    @info "CSV内すべてのフレーズ（$(num_commands)件）をベクトル化してメモリに焼き付けています..."
    
    for i in 1:num_commands
        phrase = prefix_phrases[i]
        master_embeddings[:, i] = get_embedding(model, tokenizer, phrase)
    end
    
    @info "🎉 エンジンの初期化が完了しました。メモリ常駐・BLAS演算準備完了。"
    return CommandEngine(model, tokenizer, command_ids, master_embeddings)
end

# 判定エンジンの初期化
engine = init_engine()

"""
function predict_command(engine::CommandEngine, user_input::AbstractString)

    map each word in a chat sentence to the closest vecor word in dictionary
# テキストを384次元のE5ベクトルに変換する関数（外部依存ゼロ・堅牢版）

# Arguments
- `engine::CommandEngine`: 
- `user_input::AbstractString`: chat input word
function predict_command(engine::CommandEngine, user_input::AbstractString)
- return: {Any}: vector dimention(?)
"""

# コマンド判定関数（超軽量推論レイヤー）
#function predict_command(engine::CommandEngine, user_input::AbstractString)
function predict_command(user_input::AbstractString)
    threshold = parse(Float64, j_config.JC["onnxthreshold"])

    # セキュリティ：プロンプト注入対策として入力の先頭に独自Prefixを強制結合
#    secured_input = PREFIX * user_input
    secured_input = string(PREFIX,":",user_input)
#    @info "1 " engine.model
#    @info "2 " engine.tokenizer
    @info "3 " secured_input
    # ユーザー入力をベクトル化
    user_vec = get_embedding(engine.model, engine.tokenizer, secured_input)
    
    # 爆速コサイン類似度判定（BLAS行列演算による総当たり）
    similarities = engine.master_embeddings' * user_vec
    @info "4 " similarities
    # 最も高い類似度スコアとそのインデックスを抽出
    max_score, max_idx = findmax(similarities)
    @info "5 " max_score
    @info "6 " max_idx
    # 安全弁（しきい値判定）
    if max_score < threshold
        return "CMD_NOT_FOUND", max_score
    end
    
    return engine.command_ids[max_idx], max_score
end
"""
function getAiChatCommand(chat_sentence::String)

    hear the user's command then apply it to the command list

# Arguments
- `chat_sentence::String`: chat input word
- return : tuple (command, score)
"""
function getAiChatCommand(chat_sentence)
#    cmd_id, score = predict_command(engine, chat_sentence)
    cmd_id, score = predict_command(chat_sentence)

#    if j_config.JC["debug"]
        @info string("JAiE5ChatController.getAiChatCommand(): ", chat_sentence, " -> ", cmd_id, " & ", score)
#    end

    return cmd_id, score
end
end