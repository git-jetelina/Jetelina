"""
module: JAiE5ChatController

Author: Ono keiji

Description:
	AI inference for jetelina chatting
    using Microsoft Multilingual E5 Text Enbeddings

functions
    get_embedding(model::ONNXRunTime.InferenceSession, tokenizer::HuggingFaceTokenizers.Tokenizer, text::String) convert text into 384-dimensional E5 vectors.
    init_engine() inititialize E5 engine
    predict_command(engine::CommandEngine, user_input::AbstractString) predict user input string as command with E5 engine
    getAiChatCommand(chat_sentence::String) find the command against the user input sentence
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

struct CommandEngine
    model::ONNXRunTime.InferenceSession
    tokenizer::HuggingFaceTokenizers.Tokenizer
    command_ids::Vector{String}
    master_embeddings::Matrix{Float32} 
end

"""
function get_embedding(model::ONNXRunTime.InferenceSession, tokenizer::HuggingFaceTokenizers.Tokenizer, text::String)

    convert text into 384-dimensional E5 vectors.

# Arguments
- `model::ONNXRunTime.InferenceSession`: 
- `tokenizer::HuggingFaceTokenizers.Tokenizer`:
- `text::String`: chat input word
- return: {Any}: vector dimention(?)
"""
function get_embedding(model::ONNXRunTime.InferenceSession, tokenizer::HuggingFaceTokenizers.Tokenizer, text::String)
    # tokenizing the text
    result = HuggingFaceTokenizers.encode(tokenizer, text)
    ids = Int64.(result.ids)
    len = length(ids)
    
    # create 3 tensol that are demanded on ONNX
    input_ids = reshape(ids, 1, len)
    attention_mask = reshape(ones(Int64, len), 1, len)
    token_type_ids = reshape(zeros(Int64, len), 1, len)
    
    # execute ONNX inference
    outputs = model((
        input_ids = input_ids, 
        attention_mask = attention_mask,
        token_type_ids = token_type_ids
    ))
    
    # parse the outing tensol
    raw_output = first(outputs)
    token_embeddings = reshape(raw_output, len, 384) 
    
    # Mean Pooling
    sum_vec = vec(sum(token_embeddings, dims=1))
    pooled_vec = Float32.(sum_vec ./ len)
    
    # Essential processing to convert cosine similarity into ultra-fast inner product calculation.
    return pooled_vec / norm(pooled_vec)
end
"""
function init_engine()

    inititialize E5 engine

# Arguments
- return {ANY}: dictionary data for AI chatting
"""
function init_engine()
    @info "--- init ONNX engine ---"
    
    if !isfile(MODEL_PATH)
        @info "Not Found ONNX model in " MODEL_PATH
    end
    if !isfile(CSV_PATH)
        @info "Not Found " CSV_PATH
    end
    
    @info "--- Loading ONNX model ---"
    model = ONNXRunTime.load_inference(MODEL_PATH)
    
    @info "--- Reading tokenizer ---"
    tokenizer = HuggingFaceTokenizers.from_pretrained(Tokenizer, "intfloat/multilingual-e5-small")
    
    @info "--- Loading Jetelina commands ---"
    df = CSV.read(CSV_PATH, DataFrame, header=false, stringtype=String)
    rename!(df, [:command_id, :raw_phrases])

    df.parsed_phrases = map(df.raw_phrases) do val
        clean_str = replace(val, r"[\[\]']" => "")
        return strip.(split(clean_str, ","))
    end

    df_expanded = flatten(df, :parsed_phrases)
    command_ids = Vector{String}(df.command_id)
    num_commands = length(command_ids)
    prefix_phrases = string(j_config.JC["onnxprefix"], ":") .* df_expanded.parsed_phrases
    master_embeddings = Matrix{Float32}(undef, 384, num_commands)
    
    for i in 1:num_commands
        phrase = prefix_phrases[i]
        master_embeddings[:, i] = get_embedding(model, tokenizer, phrase)
    end
    
    @info "--- Finish the initialization ---"
    return CommandEngine(model, tokenizer, command_ids, master_embeddings)
end

# initialize the E5 ONNX engine
engine = init_engine()

"""
function predict_command(engine::CommandEngine, user_input::AbstractString)

    predict user input string as command with E5 engine
    
# Arguments
- `engine::CommandEngine`: 
- `user_input::AbstractString`: chat input word
function predict_command(engine::CommandEngine, user_input::AbstractString)
- return: {Any}: vector dimention(?)
"""
function predict_command(user_input::AbstractString)
    threshold = parse(Float64, j_config.JC["onnxthreshold"])

    secured_input = string(PREFIX,":",user_input)
    # victornize of user input
    user_vec = get_embedding(engine.model, engine.tokenizer, secured_input)
    # compare user vector with engine
    similarities = engine.master_embeddings' * user_vec
    # find the most similarity index
    max_score, max_idx = findmax(similarities)

    if max_score < threshold
        return "CMD_NOT_FOUND", max_score
    end
    
    return engine.command_ids[max_idx], max_score
end
"""
function getAiChatCommand(chat_sentence::String)

    find the command against the user input sentence

# Arguments
- `chat_sentence::String`: chat input word
- return : tuple (command, score)
"""
function getAiChatCommand(chat_sentence)
    cmd_id, score = predict_command(chat_sentence)

    if j_config.JC["debug"]
        @info string("JAiE5ChatController.getAiChatCommand(): ", chat_sentence, " -> ", cmd_id, " & ", score)
    end

    return cmd_id, score
end
end