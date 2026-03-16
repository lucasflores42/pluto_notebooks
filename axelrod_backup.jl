### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 6f73fb90-1fe2-11f1-0414-11d86a3ffab9
using PlutoUI

# ╔═╡ b6147850-9dfa-4821-bb67-369482849241
md"""
# Axelrod's Tournament
"""

# ╔═╡ bbaed9d7-2d7f-44a9-9f2c-91d33049b6a3
md"""
Lets play a game!

You committed a crime with a friend, and both got arrested without enough evidence to convict for the full sentence in jail. Each of you are isolated and given the choice:

a) (Defect) Confess and testify against your friend, avoiding prison and framing him;

b) (Cooperate) Stay silent, and go to prison for a small time.

The problem is that your friend got the same deal, and if you stay silent you may get all the blame and a full sentence in jail.

This is the famous Prisoner's Dilemma, and It's formally defined by the payoff matrix
"""

# ╔═╡ c49b57ff-790d-4b8e-b8e6-4c261b54b9f3
md"""
```math
\begin{array}{c|cc}
      & C & D \\
    \hline
  C & -5 & -10 \\
  D & 0 & -7
\end{array}
```
"""

# ╔═╡ c6919b05-b594-4ed2-8550-721e67ca1f14
md"""
where each element is the number of jail time you get for a pair of choices. In this game, the best outcome you can get is to always defect and blame your friend, decreasing your jail time.

But now let's consider that this game happens $n$ times. Now your friend can retaliate in the future, and maybe cooperation is viable in the long run. The Axelrod's tournament explores this scenario. And in this post, you will play this game against some of the most famous strategies proposed.

Good luck!

"""

# ╔═╡ f606151f-9519-41b6-a69e-ffe770fa7b90
md"""
## Tournament
"""

# ╔═╡ b00f0dc0-a067-4507-bfd5-36ae600d63b5
@bind play_C CounterButton("Play C")

# ╔═╡ 0a792571-0b43-49b2-bea3-8daf6a3dbd9c
@bind play_D CounterButton("Play D")

# ╔═╡ f2b52ce7-73a5-42d3-8055-7cb02cc06f98
@bind reset CounterButton("Reset")

# ╔═╡ af2fe049-20f5-4b90-9e1a-671b12f8e7fc
md"""
## Code
"""

# ╔═╡ 806d9d6f-3079-4881-9b76-012d6595de23
PlutoUI.TableOfContents(title="", aside=true)	

# ╔═╡ dc15c3be-bb7d-43c3-8141-c5f97cd412bf
turns = 10

# ╔═╡ 3b0033d2-3deb-4f5b-bf26-e73f5eda2c40
md"""
## Strategies definitions
"""

# ╔═╡ b61191fe-1176-4286-a9b1-e44abab1077c
function ALLC(a, b)
    return 1
end

# ╔═╡ b90ffb4a-593f-4221-a78b-ce18f138e975
function ALLD(a, b)
    return 0
end

# ╔═╡ e6948e81-3d5b-46cc-8af5-514f0a914b28
function RANDOM(a, b)
    return 0.5
end

# ╔═╡ 80a72044-ab37-4669-94a8-7e8defc5e76b
function GRIM(a, b)
	if b === nothing  # first move, player hasn't played yet
        return 1
	elseif b == "D"  # if opponent defects, defects
        return 0
	elseif a == "D" # if GRIM defected, keep defecting
		return 0
    else
        return 1
    end
end

# ╔═╡ 8a242f72-9b42-43a9-ae44-d13fa1d586f6
function TFT(a, b)
	# P(C|C,C): prob. to cooperate given the result C,C in the previous round
    if b === nothing  # first move, player hasn't played yet
        return 1
    elseif b == "C"
        return 1
    else
        return 0
    end
end

# ╔═╡ 794643f5-aada-4001-ae30-d1a61641bc73
function WSLS(a, b)
    if a === nothing || b === nothing
        return 1 # first move, cooperate
    elseif (a == "C" && b == "C") || (a == "D" && b == "D")
        return 1
    else
        return 0
    end
end

# ╔═╡ 3aa5eb17-a810-40ca-9637-0f7ca07eac12
strategies = [ALLC, ALLD, RANDOM, GRIM, TFT, WSLS]

# ╔═╡ 9bebaa7d-f412-42e0-b66e-aa2e7ba56a96
function payoff(a,b)

	R, S, T, P = 5, 0, 10, 3 
	
	if a == "C" && b == "C"
		score = R
	elseif a == "C" && b == "D"
		score = S
	elseif a == "D" && b == "C"
		score = T
	else
		score = P
	end

	return score
end

# ╔═╡ 3e94c422-d9cf-4219-b6ec-262b59eceaf4
md"""
## Game 
"""

# ╔═╡ 9202df44-2b4d-4474-ae01-d4c75abcace0
mutable struct GameState
    your_history::Vector{String}
    opponent_history::Vector{String}

    your_score::Int
    opponent_score::Int

    your_previous_choice::Union{Nothing,String}
    opponent_previous_choice::Union{Nothing,String}

    current_strategy::Int
    turn::Int
    turns_per_match::Int

    your_vs_strategy_scores::Vector{Int}
	strategy_vs_you_scores::Vector{Int}

    last_play_C::Int
    last_play_D::Int
    last_reset::Int
end

# ╔═╡ 6968111d-9f4f-4768-a1ec-286e478610ca
if !@isdefined(game)
    game = GameState(
        String[], String[],
        0, 0,
        nothing, nothing,
        1, 0, turns,
        Int[], Int[],
        0, 0, 0
    )
end

# ╔═╡ 820a390f-2b9b-4098-a602-afd04f35af0e
begin

    # RESET TOURNAMENT
    if reset > game.last_reset

        empty!(game.your_history)
        empty!(game.opponent_history)

        game.your_score = 0
        game.opponent_score = 0

        game.your_previous_choice = nothing
        game.opponent_previous_choice = nothing

        game.current_strategy = 1
        game.turn = 0

        empty!(game.your_vs_strategy_scores)
        empty!(game.strategy_vs_you_scores)

        game.last_play_C = play_C
        game.last_play_D = play_D

        game.last_reset = reset
        println("Tournament reset.")

    end

    # detect player move
    your_choice = nothing
    if play_C > game.last_play_C
        your_choice = "C"
        game.last_play_C = play_C
    elseif play_D > game.last_play_D
        your_choice = "D"
        game.last_play_D = play_D
    end

    # play turn
    if your_choice !== nothing && game.current_strategy <= length(strategies)

        r = strategies[game.current_strategy]
        prob_c = r(game.opponent_previous_choice, game.your_previous_choice)

        opponent_choice = rand() < prob_c ? "C" : "D"

        push!(game.your_history, your_choice)
        push!(game.opponent_history, opponent_choice)

        game.your_score += payoff(your_choice, opponent_choice)
        game.opponent_score += payoff(opponent_choice, your_choice)

        game.your_previous_choice = your_choice
        game.opponent_previous_choice = opponent_choice

        game.turn += 1

        println("Strategy $(game.current_strategy) vs you\n")
        println("Turn $(game.turn)")
        println("You chose $your_choice")
        println("Opponent chose $opponent_choice\n")
        println("Your score: $(game.your_score)")
        println("Opponent score: $(game.opponent_score)\n")
        println("Your history: ", game.your_history)
        println("Opponent history: ", game.opponent_history)

    end

    # END OF MATCH
    if game.turn == game.turns_per_match

        println("\nMatch finished against strategy $(game.current_strategy)")
        println("Final score: $(game.your_score) vs $(game.opponent_score)")

        push!(game.your_vs_strategy_scores, game.your_score)
        push!(game.strategy_vs_you_scores, game.opponent_score)

        game.current_strategy += 1
        game.turn = 0

        empty!(game.your_history)
        empty!(game.opponent_history)

        game.your_score = 0
        game.opponent_score = 0

        game.your_previous_choice = nothing
        game.opponent_previous_choice = nothing

    end

    # END OF TOURNAMENT
    if game.current_strategy > length(strategies)

        println("\nTOURNAMENT FINISHED\n")
        total_score = sum(game.your_vs_strategy_scores)
        println("Total score: $total_score")
    end

    # calculate rest of tournament (strategies vs strategies)
    if length(game.your_vs_strategy_scores) == length(strategies)

        println("\nRunning strategy vs strategy matches...\n")

        n = length(strategies)
        strategy_scores = zeros(Int, n)

        for i in 1:n
            for j in i+1:n
			#for j in 1:n
                prev1 = nothing
                prev2 = nothing
                score1 = 0
                score2 = 0

                for t in 1:game.turns_per_match
                    # strategy i move
                    s1 = strategies[i]
                    prob1 = s1(prev1, prev2)
                    move1 = rand() < prob1 ? "C" : "D"

                    # strategy j move
                    s2 = strategies[j]
                    prob2 = s2(prev2, prev1)
                    move2 = rand() < prob2 ? "C" : "D"

                    score1 += payoff(move1, move2)
                    score2 += payoff(move2, move1)

                    prev1 = move1
                    prev2 = move2
                end

                strategy_scores[i] += score1
                strategy_scores[j] += score2

                println("Match $(nameof(strategies[i])) vs $(nameof(strategies[j]))")
                println("Score: $score1 vs $score2\n")
            end
        end

        println("================================")
        println("         FINAL RANKING ")
        println("================================")

        names = String[]
        scores = Int[]

        # add you
        push!(names, "YOU")
        push!(scores, sum(game.your_vs_strategy_scores))

        # add strategies
        for i in 1:n
            total = strategy_scores[i] + game.strategy_vs_you_scores[i]
            push!(names, string(nameof(strategies[i])))
            push!(scores, total)
        end

        # sort by score (descending)
        order = sortperm(scores, rev=true)

        for k in order
            println("$(names[k]) → $(scores[k])")
        end

    end

end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoUI = "~0.7.79"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.2"
manifest_format = "2.0"
project_hash = "03bbe4aa2214ac7d2dde4202f5de35f2c8dbd025"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

    [deps.ColorTypes.weakdeps]
    StyledStrings = "f489334b-da3d-4c2e-b8f0-e476e12c162b"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.0+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "3ac7038a98ef6977d44adeadc73cc6f596c08109"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.79"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─b6147850-9dfa-4821-bb67-369482849241
# ╟─bbaed9d7-2d7f-44a9-9f2c-91d33049b6a3
# ╟─c49b57ff-790d-4b8e-b8e6-4c261b54b9f3
# ╟─c6919b05-b594-4ed2-8550-721e67ca1f14
# ╟─f606151f-9519-41b6-a69e-ffe770fa7b90
# ╟─b00f0dc0-a067-4507-bfd5-36ae600d63b5
# ╟─0a792571-0b43-49b2-bea3-8daf6a3dbd9c
# ╟─f2b52ce7-73a5-42d3-8055-7cb02cc06f98
# ╟─820a390f-2b9b-4098-a602-afd04f35af0e
# ╟─af2fe049-20f5-4b90-9e1a-671b12f8e7fc
# ╠═6f73fb90-1fe2-11f1-0414-11d86a3ffab9
# ╠═806d9d6f-3079-4881-9b76-012d6595de23
# ╠═3aa5eb17-a810-40ca-9637-0f7ca07eac12
# ╠═dc15c3be-bb7d-43c3-8141-c5f97cd412bf
# ╠═3b0033d2-3deb-4f5b-bf26-e73f5eda2c40
# ╠═b61191fe-1176-4286-a9b1-e44abab1077c
# ╠═b90ffb4a-593f-4221-a78b-ce18f138e975
# ╠═e6948e81-3d5b-46cc-8af5-514f0a914b28
# ╠═80a72044-ab37-4669-94a8-7e8defc5e76b
# ╠═8a242f72-9b42-43a9-ae44-d13fa1d586f6
# ╠═794643f5-aada-4001-ae30-d1a61641bc73
# ╠═9bebaa7d-f412-42e0-b66e-aa2e7ba56a96
# ╠═3e94c422-d9cf-4219-b6ec-262b59eceaf4
# ╠═9202df44-2b4d-4474-ae01-d4c75abcace0
# ╠═6968111d-9f4f-4768-a1ec-286e478610ca
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
