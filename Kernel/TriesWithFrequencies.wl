(* ::Package:: *)

(* :Title: TriesWithFrequencies *)
(* :Context: TriesWithFrequencies` *)
(* :Author: Anton Antonov *)
(* :Date: 2018-04-16 *)

(* :Package Version: 1.0 *)
(* :Mathematica Version: 11.3 *)
(* :Copyright: (c) 2018 Anton Antonov *)
(* :Keywords: *)
(* :Discussion:

  # Tries with frequencies (for sequencial data mining)

  - Follows very closely (it is the same as):

    https://github.com/antononcube/MathematicaForPrediction/blob/master/TriesWithFrequencies.m

  - Duplicates the functionalities of TriesWithFrequencies.m:

    https://github.com/antononcube/MathematicaForPrediction/blob/master/TriesWithFrequenciesV9.m

  using Associations.


  ## Design

  An Association Trie with Frequencies (ATF) has the form:

    <| key1 -> <| $TrieValue->_?NumberQ, ___ |> |>

  Here is a concrete example:

    <|a1 -> <|$TrieValue -> 3, b1 -> <|$TrieValue -> 2, c1 -> <|$TrieValue -> 1|>, c2 -> <|$TrieValue -> 1|>|>, b2 -> <|$TrieValue -> 1|>|>|>

  In most cases the top-most key is $TrieRoot. For example, examine the result of

    TrieCreate[{{a1, b1, c1}, {a1, b1, c2}, {a1, b2}}]

    (* <|$TrieRoot -> <|$TrieValue -> 3, a1 -> <|b1 -> <|c1 -> <|$TrieValue -> 1|>,
         c2 -> <|$TrieValue -> 1|>, $TrieValue -> 2|>, b2 -> <|$TrieValue -> 1|>, $TrieValue -> 3|>|>|> *)

*)

BeginPackage["AntonAntonov`TriesWithFrequencies`"];

$TrieRoot::usage = "Symbol marking the root of a trie.";

$TrieValue::usage = "Symbol used as a key for a trie node value.";

TrieQ::usage = "A predicate is an expression a trie.";

TrieWithTrieRootQ = "A predicate is an expression a trie with a root that is $TrieRoot.";

TrieBodyQ::usage = "A predicate is an expression a trie body.";

TrieRuleQ::usage = "A predicate is an expression a trie rule.";

TrieValueRuleQ::usage = "A predicate is an expression a trie value rule.";

TrieRetrieve::usage = "TrieRetrieve[t_, w_List] gives the node corresponding to the last \"character\" of the \"word\" w in the trie t.";

TrieSubTrie::usage = "TrieSubTrie[t_, w_List] gives the sub-trie corresponding to the last \"character\" of the \"word\" w in the trie t.";

TriePosition::usage = "TriePosition[ tr_, ks_List ] finds a sub-list of the list of keys \
ks that corresponds to a sub-trie in the trie tr.";

ToTrieWithRoot::usage = "ToTrieWithRoot[tr] convert a trie into trie with root.";

TrieBlank::usage = "TrieBlank[] makes a blank trie.";

TrieCreate::usage = "TrieCreate[words:{_List..}] creates a trie from a list of lists.";

TrieCreateBySplit::usage = "TrieCreateBySplit[ ws:{_String..}, patt:\"\"] creates a trie object \
from a list of strings that are split with a given pattern patt.";

TrieInsert::usage = "TrieInsert[t_, w_List] insert a \"word\" to the trie t. \
TrieInsert[t_, w_List, val_] inserts a key and a corresponding value.";

TrieMerge::usage = "TrieMerge[t1_, t2_] merges two tries.";

TrieShrink::usage = "TrieShrink[tr_?TrieQ] shrinks the leaves and internal nodes of the trie tr into prefixes. \
TrieShrink[tr_?TrieQ, sep_String] does the shrinking of string nodes with the string separator sep.";

TrieToRules::usage = "Converts a trie into a list of rules suitable for visualization with GraphPlot and LayeredGraphPlot. \
To each trie node is added a list of its level and its traversal order.";

TrieForm::usage = "Graph plot for a trie.";

TrieValueTotal::usage = "TrieValueTotal[trb_?TrieBodyQ] gives the total sum of the values in a trie body.";

TrieNodeProbabilities::usage = "Converts the frequencies at the nodes of a trie into probabilities. \
The value of the option \"ProbabilityModifier\" is a function that is applied to the computed probabilities.";

TrieNodeFrequencies::usage = "Converts the probabilities at the nodes of a trie into frequencies. \
The value of the option \"FrequencyModifier\" is a function that is applied to the computed frequencies.";

TrieLeafProbabilities::usage = "Gives the probabilities to end up at each of the leaves by paths from the root of the trie.";

TrieLeafProbabilitiesWithPositions::usage = "Gives the probabilities to end up at each of the leaves by paths from the root of the trie. \
For each leaf its position in the trie is given.";

TriePathFromPosition::usage = "TriePathFromPosition[trie,pos] gives a list of nodes from the root of a trie to the node at a specified position.";

TrieRootToLeafPaths::usage = "TrieRootToLeafPaths[trie] gives all paths from the root node to the leaf nodes.";

TrieRootToLeafPathRules::usage = "TrieRootToLeafPathRules[trie] gives rules for all paths from the root node to the leaf node values.";

TrieRootToLeafPathProbabilityRules::usage = "TrieRootToLeafPathProbabilityRules[trie] gives path probability rules \
for all paths from the root node to the leaf nodes.";

TrieGetWords::usage = "TrieGetWords[ tr_, sw_List ] gives a list words in tr that start with sw. \
The second argument can be All.";

TrieRemove::usage = "TrieRemove removes a \"word\" from a trie.";

TrieThresholdRemove::usage = "TrieThresholdRemove[tr_, th_?NumberQ, opts] removes nodes that have values below \
a specified threshold. \
If the value postfixVal of the option \"Postfix\" is different than NULL or None then \
the dropped nodes are replaced with postfixVal -> removedTotal, \
where removedTotal is the total of the values of the dropped nodes. \
If the option \"BelowThreshold\" is to False, the nodes with values above the threshold are removed";

TrieParetoFractionRemove::usage = "TrieParetoFractionRemove[tr_, fr_?NumberQ, opts] removes nodes that have values
below the thresholds derived by the specified Pareto principle fraction. \
If the value postfixVal of the option \"Postfix\" is different than NULL or None then \
the dropped nodes are replaced with postfixVal -> removedTotal, \
where removedTotal is the total of the values of the dropped nodes. \
If the option \"RemoveBottomElements\" is set to False, \
then the nodes with Pareto values below the derived thresholds are removed.";

TrieHasCompleteMatchQ::usage = "TrieHasCompleteMatchQ[ tr_, sw_List ] finds does a fraction \
of the list sw is a complete match in the trie tr.";

TrieContains::usage = "TrieContains[ tr_, sw_List ] finds is the list sw a complete match in the trie tr.";

TrieMemberQ::usage = "Same as TrieContains.";

TrieKeyExistsQ::usage = "TrieKeyExistsQ[tr_, sw_List] finds is the list sw a key in the trie tr.";

TrieKeyQ::usage = "Synonym of TrieKeyExistsQ.";

TriePrune::usage = "TriePrune[t, maxLvl] prunes the trie to a maximum node level. (The root is level 0.)";

TrieKeyValueTraverse::usage = "TrieKeyValueTraverse[t, composeFunc, joinFunc, nodeFunc] traverses a trie.";

TrieKeyTraverse::usage = "TrieKeyTraverse[t, composeFunc, joinFunc] traverses the keys of a trie.";

TrieRandomChoice::usage = "TrieRandomChoice[t, n] gives n random \"words\" from the trie t.";

TrieMap::usage = "TrieMap[t, preFunc, postFunc] traverses the trie t and applies preFunc and postFunc at each node.";

TrieNodeCounts::usage = "TrieNodeCounts[t] gives and association with the total number of nodes, internal nodes only, and leaves only.";

TrieDepth::usage = "TrieDepth[tr] gives the maximum level of the trie tr.";

TrieToJSON::usage = "TrieToJSON[tr] converts a trie to a corresponding JSON expression.";

TrieToListTrie::usage = "TrieToListTrie[tr] converts an Association based trie to a List based trie. (The \"old\" approach.)";

ToTrieFromJSON::usage = "ToTrieFromJSON[jsonTrie:{_Rule...}] converts a JSON import into a Trie object. \
ToTrieFromJSON[jsonTrie:{_Rule...}, elementNames:{key_String, value_String, children_String}] is going to use \
the specified element names for the conversion.";

TrieComparisonGrid::usage = "Makes a grid trie plots for a specified list of trie expressions.";

TrieClassify::usage = "TrieClassify[tr_,record_] classifies a record using a trie. \
The signature TrieClassify[tr_,record_,prop_] can take properties as the ones given to ClassifierFunction. \
TrieClassify[tr_,record_] is the same as TrieClassify[tr_,record_,\"Decision\"].";


Begin["`Private`"];

(************************************************************)
(* Trie predicates                                          *)
(************************************************************)

Clear[TrieBodyQ];
SyntaxInformation[TrieBodyQ] = { "ArgumentsPattern" -> { _ } };
TrieBodyQ[a_Association] := KeyExistsQ[a, $TrieValue];
TrieBodyQ[___] := False;

Clear[TrieQ];
SyntaxInformation[TrieQ] = { "ArgumentsPattern" -> { _ } };
TrieQ[a_Association] := MatchQ[a, Association[x_ -> b_?TrieBodyQ]];
TrieQ[___] := False;

Clear[TrieRuleQ];
SyntaxInformation[TrieRuleQ] = { "ArgumentsPattern" -> { _ } };
TrieRuleQ[a_Rule] := MatchQ[a, Rule[x_, b_?TrieBodyQ]];
TrieRuleQ[___] := False;

Clear[TrieValueRuleQ];
SyntaxInformation[TrieValueRuleQ] = { "ArgumentsPattern" -> { _ } };
TrieValueRuleQ[a_Rule] := MatchQ[a, Rule[$TrieValue, _]];
TrieValueRuleQ[___] := False;

Clear[TrieWithTrieRootQ];
TrieWithTrieRootQ[a_Association] := MatchQ[a, Association[$TrieRoot -> b_?TrieBodyQ]];
TrieWithTrieRootQ[___] := False;


(************************************************************)
(* Trie stats                                               *)
(************************************************************)

Clear[TrieNodeCounts];
SyntaxInformation[TrieNodeCounts] = { "ArgumentsPattern" -> { _ } };
TrieNodeCounts[tr_] :=
    Block[{cs},
      cs = {Count[tr, <|___, $TrieValue -> _, ___|>, Infinity], Count[tr, <|$TrieValue -> _|>, Infinity]};
      <|"total" -> cs[[1]], "internal" -> cs[[1]] - cs[[2]], "leaves" -> cs[[2]]|>
    ];

Clear[TrieDepth];
SyntaxInformation[TrieDepth] = { "ArgumentsPattern" -> { _ } };
TrieDepth[tr_?TrieQ] := Depth[tr] - 2;


(************************************************************)
(* Trivial trie                                             *)
(************************************************************)

Clear[TrieBlank];
TrieBlank[] := <|$TrieRoot -> <|$TrieValue -> 0|>|>;


(************************************************************)
(* Trie conversion                                          *)
(************************************************************)

Clear[ToTrieWithRoot];

ToTrieWithRoot[ tr_?TrieWithTrieRootQ ] := tr;

ToTrieWithRoot[ tr_?TrieQ ] :=
    Block[{},
      <| $TrieRoot -> Join[ <| $TrieValue -> tr[[1]][$TrieValue] |>, tr ] |>
    ] /; !TrieWithTrieRootQ[tr];


(************************************************************)
(* Trie merge related                                       *)
(************************************************************)

Clear[TrieMerge];

SyntaxInformation[TrieMerge] = { "ArgumentsPattern" -> { _, _ } };

TrieMerge[<||>, <||>] := <||>;
TrieMerge[t1_?TrieQ, t2_?TrieQ] :=
    Block[{ckey},
      Which[
        TrueQ[Keys[t1] == Keys[t2]],
        ckey = First@Keys[t1];
        <|
          ckey ->
              Join[
                Merge[{t1[ckey], t2[ckey]}, TrieMerge],
                <|$TrieValue -> (t1[ckey][$TrieValue] + t2[ckey][$TrieValue])|>
              ]
        |>,

        True,
        Join[t1, t2]
      ]
    ];
TrieMerge[{<||>, t2_Association}] := t2;
TrieMerge[{t1_Association, <||>}] := t1;
TrieMerge[{t1_Association}] := t1;
TrieMerge[{t1_Association, t2_Association}] :=
    Block[{},
      Join[Merge[{KeyDrop[t1, $TrieValue], KeyDrop[t2, $TrieValue]},
        TrieMerge], <|$TrieValue -> (t1[$TrieValue] + t2[$TrieValue])|>]
    ];

Clear[TrieMake];

SyntaxInformation[TrieMake] = { "ArgumentsPattern" -> { _, _. } };

TrieMake[chars_List] := TrieMake[chars, 1];
TrieMake[chars_List, v_Integer] := TrieMake[chars, v, v];
TrieMake[chars_List, v_Integer, v0_Integer] :=
    Fold[<|#2 -> <|$TrieValue -> v, #1|>|> &, <|Last[chars] -> <|$TrieValue -> v0|>|>,
      Reverse@Most@chars];

Clear[TrieInsert];

SyntaxInformation[TrieInsert] = { "ArgumentsPattern" -> { _, _, _. } };

TrieInsert[tr_?TrieQ, word_List] :=
    TrieMerge[tr, <|$TrieRoot -> Join[<|$TrieValue -> 1|>, TrieMake[word, 1]]|>];

TrieInsert[tr_, word_List, value_] :=
    Block[{},
      TrieMerge[
        tr, <|$TrieRoot -> Join[<|$TrieValue -> 1|>, TrieMake[word, 0, value]]|>]
    ];


(************************************************************)
(* Trie creation functions                                  *)
(************************************************************)

Clear[TrieCreate1];
SyntaxInformation[TrieCreate1] = { "ArgumentsPattern" -> { _ } };
TrieCreate1[{}] := <|$TrieRoot -> <|$TrieValue -> 0|>|>;
TrieCreate1[words : {_List ..}] :=
    Fold[TrieInsert, <|
      $TrieRoot -> Join[<|$TrieValue -> 1|>, TrieMake[First[words], 1]]|>, Rest@words];


Clear[TrieCreate];
SyntaxInformation[TrieCreate] = { "ArgumentsPattern" -> { _ } };
TrieCreate[{}] := <|$TrieRoot -> <|$TrieValue -> 0|>|>;
TrieCreate[words : {_List ..}] :=
    Block[{},
      If[Length[words] <= 5, TrieCreate1[words], (*ELSE*)
        TrieMerge[TrieCreate[Take[words, Floor[Length[words] / 2]]],
          TrieCreate[Take[words, {Floor[Length[words] / 2] + 1, Length[words]}]]]
      ]
    ];

Clear[TrieCreateBySplit];
SyntaxInformation[TrieCreateBySplit] = { "ArgumentsPattern" -> { _, _. } };
TrieCreateBySplit[words : {_String ..}, patt_ : ""] :=
    TrieCreate[ Map[StringSplit[#, patt]&, words]];


(************************************************************)
(* Trie retrieval functions                                 *)
(************************************************************)

Clear[TrieSubTrie, TrieSubTriePathRec];

SyntaxInformation[TrieSubTrie] = { "ArgumentsPattern" -> { _, _ } };

TrieSubTrie::wargs = "The first argument is expected to be a trie; the second argument is expected to be a list.";

TrieSubTrie[tr_?TrieQ, wordArg_List ] :=
    Block[{path, word = wordArg},
      If[TrieWithTrieRootQ[tr] && !MatchQ[word, {$TrieRoot, ___}], word = Prepend[word, $TrieRoot] ];
      path = TrieSubTriePathRec[tr, word ];
      If[Length[path] == 0, {},
        <|Last[path] -> tr[ Sequence @@ path ]|>
      ]
    ];

TrieSubTrie[___] :=
    Block[{},
      Message[TrieSubTrie::wargs];
      $Failed
    ];

TrieSubTriePathRec[tr_, {}] := {};
TrieSubTriePathRec[tr_, word_List] :=
    If[KeyExistsQ[tr, First[word]],
      Join[{First[word]}, TrieSubTriePathRec[tr[First[word]], Rest[word]]],
      {}
    ] /; TrieBodyQ[tr] || TrieQ[tr];


Clear[TriePosition];
SyntaxInformation[TriePosition] = { "ArgumentsPattern" -> { _, _ } };
TriePosition[tr_?TrieQ, word_List] :=
    If[TrieWithTrieRootQ[tr] && !MatchQ[word, {$TrieRoot, ___}],
      TrieSubTriePathRec[tr, Prepend[word, $TrieRoot] ],
      TrieSubTriePathRec[tr, word ]
    ];

Clear[TrieRetrieve];
SyntaxInformation[TrieRetrieve] = { "ArgumentsPattern" -> { _, _ } };
TrieRetrieve[tr_?TrieQ, wordArg_List] :=
    Block[{p, word = wordArg},
      If[TrieWithTrieRootQ[tr] && !MatchQ[word, {$TrieRoot, ___}], word = Prepend[word, $TrieRoot] ];
      p = tr[ Sequence @@ word ];
      If[ FreeQ[p, _Missing], p,
        (*ELSE*)
        p = TriePosition[tr, wordArg];
        Which[
          Length[p] == 0, {},
          True, tr[ Sequence @@ p ]
        ]
      ]
    ];


(************************************************************)
(* Trie key query functions                                 *)
(************************************************************)

Clear[TrieHasCompleteMatchQ];

SyntaxInformation[TrieHasCompleteMatchQ] = { "ArgumentsPattern" -> { _, _ } };

TrieHasCompleteMatchQ[tr_?TrieQ, word_List ] :=
    Block[{pos, b},
      pos = TriePosition[tr, word];

      If[ Length[pos] == 0, Return[False] ];

      b = False;
      While[ Length[pos] > 0 && !b,
        b = TrieValueTotal[ tr[ Sequence @@ pos ] ] < tr[ Sequence @@ pos, $TrieValue ];
        pos = Most[pos];
      ];

      b
    ];

Clear[TrieContains];

SyntaxInformation[TrieContains] = { "ArgumentsPattern" -> { _, _ } };

TrieContains[tr_?TrieQ, wordArg_List ] :=
    Block[{pos, word = wordArg},

      If[ TrieWithTrieRootQ[tr] && !MatchQ[word, {$TrieRoot, ___}], word = Prepend[word, $TrieRoot] ];

      pos = TriePosition[tr, word];

      If[ Length[pos] == Length[word],
        TrieValueTotal[ tr[ Sequence @@ pos ] ] < tr[ Sequence @@ pos, $TrieValue ],
        (* ELSE *)
        False
      ]
    ];

TrieMemberQ = TrieContains;

Clear[TrieKeyExistsQ];

SyntaxInformation[TrieKeyExistsQ] = { "ArgumentsPattern" -> { _, _ } };

TrieKeyExistsQ[ tr_?TrieQ, wordArg_List ] :=
    Block[{pos, word = wordArg},
      If[ TrieWithTrieRootQ[tr] && !MatchQ[word, {$TrieRoot, ___}], word = Prepend[word, $TrieRoot] ];
      pos = TriePosition[tr, word];
      Length[pos] == Length[word]
    ];

Clear[TrieKeyQ];
TrieKeyQ = TrieKeyExistsQ;


(************************************************************)
(* TrieNodeProbabilities and related functions              *)
(************************************************************)

Clear[TrieNodeProbabilities, TrieNodeProbabilitiesRec];

SyntaxInformation[TrieNodeProbabilities] = { "ArgumentsPattern" -> { _, OptionsPattern[] } };

Options[TrieNodeProbabilities] = {"ProbabilityModifier" -> N};
Options[TrieNodeProbabilitiesRec] = Options[TrieNodeProbabilities];

TrieNodeProbabilities[tr_?TrieQ, opts : OptionsPattern[]] :=
    Block[{},
      <|First[Keys[tr]] -> Join[TrieNodeProbabilitiesRec[First@Values[tr], opts], <|$TrieValue -> 1|>]|>
    ];

TrieNodeProbabilitiesRec[trb_?TrieBodyQ, opts : OptionsPattern[]] :=
    Block[{sum, res, pm = OptionValue[TrieNodeProbabilitiesRec, "ProbabilityModifier"]},
      Which[
        Length[Keys[trb]] == 1, trb,

        True,
        If[trb[$TrieValue] == 0,
          sum = TrieValueTotal[trb],
          (*ELSE*)
          sum = trb[$TrieValue]
        ];
        res = Map[TrieNodeProbabilitiesRec[#] &, KeyDrop[trb, $TrieValue]];
        res = Replace[res, <|a___, $TrieValue -> x_, b___|> :> <|a, $TrieValue -> pm[x / sum], b|>, {1}];
        Join[res, KeyTake[trb, $TrieValue]]
      ]
    ];

Clear[TrieValueTotal];
TrieValueTotal[trb_?TrieBodyQ] := Total[Map[#[$TrieValue] &, KeyDrop[trb, $TrieValue]]];

Clear[TrieLeafProbabilities, TrieLeafProbabilitiesRec];

SyntaxInformation[TrieLeafProbabilities] = { "ArgumentsPattern" -> { _ } };

TrieLeafProbabilities::ntnode = "Non trie node was encountered: `1`. A trie node has two elements prefix and frequency.";

TrieLeafProbabilities[trieArg_?TrieQ] :=
    Block[{res},

      res =
          Which[
            TrueQ[trieArg[First@Keys@trieArg][$TrieValue] == 0],
            (* This does not match any signature. *)
            TrieLeafProbabilitiesRec[trieArg],

            True,
            TrieLeafProbabilitiesRec[First@Keys@trieArg, First@Values@trieArg]
          ];

      If[Length[res] == 1, res, Merge[res, Total]]
    ];

TrieLeafProbabilities[args__] :=
    Block[{},
      Message[TrieLeafProbabilities::ntnode, {args}];
      Return[<||>]
    ];

TrieLeafProbabilitiesRec[k_, trb_?TrieBodyQ] :=
    Block[{res, sum},

      Which[

        Length[Keys[trb]] == 1,
        {k -> trb[$TrieValue]},

        True,
        sum = TrieValueTotal[trb];
        res = KeyValueMap[TrieLeafProbabilitiesRec, KeyDrop[trb, $TrieValue]];
        If[sum < 1,
          res = Append[res, k -> (1 - sum)]
        ];
        res = Map[#[[1]] -> #[[2]] * trb[$TrieValue] &, Flatten[res, 1]]

      ]
    ];


(************************************************************)
(* TrieShrink and related functions                         *)
(************************************************************)

Clear[NodeJoin];
NodeJoin[n_String] := n;
NodeJoin[n1_String, n2_String] := n1 <> n2;
NodeJoin[n1_List, n2_String] := List[n1, n2];
NodeJoin[n_] := List[n];
NodeJoin[n1_List, n2_List] := Join[n1, n2];
NodeJoin[n1_, n2_List] := Prepend[n2, n1];
NodeJoin[n1_List, n2_] := Append[n1, n2];
NodeJoin[n1_, n2_] := List[n1, n2];

Clear[TrieShrink, TrieShrinkRec];

SyntaxInformation[TrieShrink] = { "ArgumentsPattern" -> { _, _. } };

TrieShrink::wargs = "The first argument is expected to be a trie; the second, optional argument is expected to a string.";

TrieShrink[tr_?TrieQ] := TrieShrinkRec[tr];

TrieShrink[tr_?TrieQ, sep_String] :=
    Block[{res},
      NodeJoin[n1_String, n2_String] := n1 <> sep <> n2;
      res = TrieShrinkRec[tr];
      NodeJoin[n1_String, n2_String] := n1 <> n2;
      res
    ];

TrieShrink[___] := Message[TrieShrink::wargs];

TrieShrinkRec[{}] := {};

TrieShrinkRec[tr_?TrieQ] := TrieShrinkRec[First[Normal[tr]]];

TrieShrinkRec[tr_?TrieRuleQ] :=
    Block[{vals = tr[[2]], key = tr[[1]], valKeys },
      valKeys = Keys @ KeyDrop[vals, $TrieValue];

      Which[
        Length[ vals ] == 1,
        tr,

        key =!= $TrieRoot && Length[vals] == 2 && vals[$TrieValue] == vals[First @ valKeys][$TrieValue],
        TrieShrinkRec[ <| NodeJoin[ key, First[valKeys] ] -> vals[First @ valKeys] |> ],

        True,
        <| key -> Join[ <| $TrieValue -> vals[$TrieValue] |>, Association @ Map[ TrieShrinkRec, Normal @ KeyDrop[vals, $TrieValue] ] ] |>
      ]
    ];


(************************************************************)
(* Trie root to leaf functions                              *)
(************************************************************)

(* I am not particularly happy with using FixedPoint. This has to be profiled. *)
Clear[TrieRootToLeafPaths];

SyntaxInformation[TrieRootToLeafPaths] = { "ArgumentsPattern" -> { _ } };

TrieRootToLeafPaths[tr_?TrieQ] :=
    Map[List @@@ Most[#[[1]]] &,
      FixedPoint[
        Flatten[Normal[#] /.
            Rule[n_, m_?TrieBodyQ] :>

                Which[
                  Length[m] == 1,
                  KeyMap[Append[n, #] &, m],

                  m[$TrieValue] > TrieValueTotal[m] || TrieValueTotal[m] < 1,
                  Join[ KeyMap[Append[n, # -> m[#][$TrieValue]] &, KeyDrop[m, $TrieValue]], KeyMap[Append[n, #] &, KeyTake[m, $TrieValue]] ],

                  True,
                  KeyMap[Append[n, # -> m[#][$TrieValue]] &, KeyDrop[m, $TrieValue]]], 1] &,
        KeyMap[{# -> First[Values[tr]][$TrieValue]} &, tr]]
    ];

(* This is implemented because it looks neat, and it can be used for tensor creation. *)
Clear[TrieRootToLeafPathRules];
TrieRootToLeafPathRules[tr_?TrieQ] :=
    Association[
      Map[ Most[#[[1]]] -> #[[2]] &,
        FixedPoint[
          Flatten[Normal[#] /.
              Rule[n_, m_?TrieBodyQ] :>
                  If[Length[m] == 1 || m[$TrieValue] > TrieValueTotal[m] || TrieValueTotal[m] < 1,
                    KeyMap[Append[n, #] &, m],
                    KeyMap[Append[n, #] &, KeyDrop[m, $TrieValue]]], 1] &,
          KeyMap[{#} &, tr]
        ]
      ]
    ];

Clear[TrieRootToLeafPathProbabilityRules];
TrieRootToLeafPathProbabilityRules[tr_?TrieQ] :=
    ReverseSort @ Association @ Map[ #[[All, 1]] -> Apply[Times, #[[All, 2]]] &, TrieRootToLeafPaths[tr] ];


(************************************************************)
(* TrieGetWords                                             *)
(************************************************************)

Clear[TrieGetWords];

SyntaxInformation[TrieGetWords] = { "ArgumentsPattern" -> { _, _. } };

TrieGetWords::args = "The first of argument is expected to be a trie, the second argument is expected to be a list or All.";

TrieGetWords[ tr_?TrieQ, word : ( _List | All ) : All ] :=
    Which[

      TrueQ[word === All] || ListQ[word] && Length[word] == 0,
      Map[ Join, Keys @ TrieRootToLeafPathRules[tr] ],

      ListQ[word] || TrieKeyExistsQ[tr, word],
      Map[ Join[Most[word], #]&, Keys @ TrieRootToLeafPathRules[TrieSubTrie[tr, word]] ],

      True,
      {}
    ];

TrieGetWords[___] :=
    Block[{},
      Message[TrieGetWords::args];
      $Failed
    ];


(************************************************************)
(* TriePrune                                                *)
(************************************************************)

Clear[TriePrune, TriePruneRec];

SyntaxInformation[TriePrune] = { "ArgumentsPattern" -> { _, _ } };

TriePrune::args = "The first argument is expected to be a trie. \
The second argument is expected to be a positive integer.";

TriePrune[trie_?TrieQ, maxLevel_Integer] :=
    Block[{},
      Association[TriePruneRec[First @ Normal @ trie, maxLevel, 0]]
    ] /; maxLevel > 0;

TriePrune[___] :=
    Block[{},
      Message[TriePrune::args];
      $Failed
    ];

TriePruneRec[tr_?TrieRuleQ, maxLevel_Integer, level_Integer] :=
    Block[{key = tr[[1]]},
      Which[
        Length[tr] == 0, {},
        Length[tr[[2]]] == 1, tr,
        maxLevel <= level, key -> KeyTake[tr[[2]], $TrieValue],
        True,
        key ->
            Join[
              Association @ KeyValueMap[ TriePruneRec[#1 -> #2, maxLevel, level + 1] &, KeyDrop[tr[[2]], $TrieValue] ],
              KeyTake[tr[[2]], $TrieValue]
            ]
      ]
    ];


(************************************************************)
(* Trie key-value traversal                                 *)
(************************************************************)

Clear[TrieKeyValueTraverse];

SyntaxInformation[TrieKeyValueTraverse] = { "ArgumentsPattern" -> { _, _., _., _. } };

TrieKeyValueTraverse::args = "The first argument is expected to be a trie.";

TrieKeyValueTraverse[tr_?TrieQ, composeFunc_ : List, joinFunc_ : List, nodeFunc_ : Identity] :=
    TrieKeyValueTraverseRec[Normal[tr][[1]], composeFunc, joinFunc, nodeFunc, 1];

TrieKeyValueTraverse[___] :=
    Block[{},
      Message[TrieKeyValueTraverse::args];
      $Failed
    ];

TrieKeyValueTraverseRec[trRule_?TrieValueRuleQ, composeFunc_, joinFunc_, nodeFunc_, lvl_Integer] := nodeFunc[trRule];

TrieKeyValueTraverseRec[trRule_?TrieRuleQ, composeFunc_, joinFunc_, nodeFunc_, lvl_Integer] :=
    Block[{res},
      res = Map[TrieKeyValueTraverseRec[#, composeFunc, joinFunc, nodeFunc, lvl + 1] &, Normal@trRule[[2]]];
      composeFunc[trRule[[1]], joinFunc @@ res]
    ];


(************************************************************)
(* Trie keys traversal                                      *)
(************************************************************)

Clear[TrieKeyTraverse];

SyntaxInformation[TrieKeyTraverse] = { "ArgumentsPattern" -> { _, _., _. } };

TrieKeyTraverse::args = "The first argument is expected to be a trie.";

TrieKeyTraverse[tr_?TrieQ, composeFunc_ : List, joinFunc_ : List] :=
    TrieKeyTraverseRec[Normal[tr][[1]], composeFunc, joinFunc, 1];

TrieKeyTraverse[___] :=
    Block[{},
      Message[TrieKeyTraverse::args];
      $Failed
    ];

TrieKeyTraverseRec[trRule_?TrieValueRuleQ, composeFunc_, joinFunc_, lvl_Integer] := {};

TrieKeyTraverseRec[trRule_?TrieRuleQ, composeFunc_, joinFunc_, lvl_Integer] :=
    Block[{res},
      res = Map[TrieKeyTraverseRec[#, composeFunc, joinFunc, lvl + 1] &, Normal@trRule[[2]]];
      res = DeleteCases[res, {}];
      If[Length[res] == 0,
        trRule[[1]],
        (*ELSE*)
        composeFunc[trRule[[1]], joinFunc @@ res]
      ]
    ];


(************************************************************)
(* Trie random choice                                       *)
(************************************************************)

Clear[TrieRandomChoice];

SyntaxInformation[TrieRandomChoice] = { "ArgumentsPattern" -> { _, _. } };

TrieRandomChoice::args = "The first argument is expected to be a trie. \
The second, optional argument is expected to be a positive integer.";

Clear[TrieRandomChoice];
TrieRandomChoice[tr_?TrieQ] :=
    First @ TrieRandomChoice[tr,1];

TrieRandomChoice[tr_?TrieQ, n_Integer] :=
    Table[TrieRandomChoiceRec[Normal[tr][[1]]][[1]], n];

Clear[TrieRandomChoiceRec];

TrieRandomChoiceRec[trRule_?TrieValueRuleQ] := trRule;

TrieRandomChoiceRec[trRule_?TrieRuleQ] :=
    Block[{recurseQ, res, childrenProb},

      childrenProb = TrieValueTotal[trRule[[2]]];
      If[ 1.0 - childrenProb < 0,
        (* This might happen around the $MachineEpsilon .*)
        childrenProb = 1.0
      ];
      recurseQ = RandomChoice[{childrenProb, 1.0 - childrenProb} -> {True, False}];

      If[! recurseQ,
        {trRule[[1]]} -> trRule[[2]][$TrieValue],
        (*ELSE*)
        (* The choice over which element to recurse should happen beforehand. *)
        res = TrieBodyElementRandomChoice[trRule[[2]]];
        res = TrieRandomChoiceRec[ res -> trRule[[2]][res] ];
        Flatten[{trRule[[1]], res[[1]]}] -> trRule[[2]][$TrieValue]
      ]
    ];

Clear[TrieBodyElementRandomChoice];
TrieBodyElementRandomChoice[trb_?TrieBodyQ] :=
    Block[{res},
      res = Map[#[$TrieValue] &, KeyDrop[trb, $TrieValue]];
      RandomChoice[ Values[res] -> Keys[res] ]
    ];


(************************************************************)
(* Trie Map                                                 *)
(************************************************************)

Clear[TrieMap, TrieMapRec];

SyntaxInformation[TrieMap] = { "ArgumentsPattern" -> {_, _, _ } };

TrieMap::funcs = "At least one of the second and third argument has to be a function.";

TrieMap[ tr_?TrieQ, preFunc_, postFunc_ ] :=
    Block[{},

      If[ ( preFunc === Null || preFunc === None ) && ( postFunc === Null || postFunc === None ),
        Message[TrieMap::funcs];
        Return[tr]
      ];

      Association[ TrieMapRec[ First @ Normal @ tr, preFunc, postFunc, 0 ] ]
    ];

TrieMapRec[tr_?TrieRuleQ, preFunc_, postFunc_, level_Integer ] :=
    Block[{res, resChildren},

      If[ Length[tr] == 0, Return[{}] ];

      If[ ! ( TrueQ[preFunc === Null] || TrueQ[preFunc === None] ),
        res = preFunc[tr],
        (* ELSE *)
        res = tr
      ];
      (*      Print @ Normal @ KeyDrop[ res[[2]], $TrieValue ] ;*)
      If[ Length[res[[2]]] == 1,
        resChildren = <||>,
        (* ELSE *)
        resChildren = Association @ Map[ TrieMapRec[#, preFunc, postFunc, level + 1]&, Normal @ KeyDrop[ res[[2]], $TrieValue ] ]
      ];

      res = res[[1]] -> Join[ KeyTake[res[[2]], $TrieValue], resChildren ];

      If[ !(TrueQ[postFunc === Null] || TrueQ[postFunc === None]),
        res = postFunc[res]
      ];

      res
    ];


(************************************************************)
(* Trie threshold removal                                   *)
(************************************************************)

Clear[TrieThresholdRemove];

SyntaxInformation[TrieThresholdRemove] = { "ArgumentsPattern" -> {_, _, OptionsPattern[]} };

Options[TrieThresholdRemove] = {"Postfix" -> Anonymous, "BelowThreshold" -> True};

TrieThresholdRemove[ tr_?TrieQ, threshold_?NumberQ, opts : OptionsPattern[] ] :=
    Block[{postfix, belowThresholdQ},

      postfix = OptionValue[TrieThresholdRemove, "Postfix"];
      belowThresholdQ = TrueQ[OptionValue[TrieThresholdRemove, "BelowThreshold"]];

      TrieMap[ tr, ThresholdRemove[#, threshold, postfix, belowThresholdQ] &, None]
    ];


Clear[ThresholdRemove];

ThresholdRemove[tr_?TrieRuleQ, threshold_?NumberQ, postfix_, belowThresholdQ : (True | False) ] :=
    Block[{resChildren, removeSum},

      If[Length[KeyDrop[tr, $TrieValue]] == 0, Return[tr]];

      If[ belowThresholdQ,
        resChildren = Select[KeyDrop[tr[[2]], $TrieValue], #[$TrieValue] >= threshold &],
        (* ELSE *)
        resChildren = Select[KeyDrop[tr[[2]], $TrieValue], #[$TrieValue] <= threshold &]
      ];

      If[! (TrueQ[postfix === None] || TrueQ[postfix === Null]) && Length[resChildren] < Length[tr[[2]]] - 1,

        removeSum = Total @ Map[ #[$TrieValue] &, KeyDrop[tr[[2]], Prepend[ Keys[resChildren], $TrieValue] ] ];

        resChildren = Append[resChildren, postfix -> <|$TrieValue -> removeSum|>]
      ];

      tr[[1]] -> Join[KeyTake[tr[[2]], $TrieValue], resChildren]
    ];


(************************************************************)
(* Trie Pareto fraction removal                             *)
(************************************************************)

Clear[TrieParetoFractionRemove];

TrieParetoFractionRemove::pfrac = "The second argument is expected to be a number between 0 and 1.";

SyntaxInformation[TrieParetoFractionRemove] = { "ArgumentsPattern" -> {_, _, OptionsPattern[]} };

Options[TrieParetoFractionRemove] = {"Postfix" -> Anonymous, "RemoveBottomElements" -> True};

TrieParetoFractionRemove[ tr_?TrieQ, paretoFraction_?NumberQ, opts : OptionsPattern[] ] :=
    Block[{postfix, removeBottomElementsQ},

      postfix = OptionValue[TrieParetoFractionRemove, "Postfix"];
      removeBottomElementsQ = TrueQ[OptionValue[TrieParetoFractionRemove, "RemoveBottomElements"]];

      If[ !( 0 <= paretoFraction <= 1),
        Message[TrieParetoFractionRemove::pfrac];
        Return[$Failed]
      ];

      TrieMap[ tr, ParetoThresholdRemove[#, paretoFraction, postfix, removeBottomElementsQ] &, None]
    ];


(* Essentially the same as ThresholdRemove, except here we have accumulation and threshold calculation. *)
Clear[ParetoThresholdRemove];

ParetoThresholdRemove[tr_?TrieRuleQ, paretoFraction_?NumberQ, postfix_, removeBottomElementsQ : (True | False) ] :=
    Block[{children, acc, threshold, resChildren, removeSum},

      children = KeyDrop[ tr[[2]], $TrieValue ];

      If[Length[children] == 0, Return[tr]];

      children = Reverse[ SortBy[ children, #[$TrieValue]& ] ];

      acc = Accumulate[ Values @ Map[ #[$TrieValue]&, children ] ];
      acc = AssociationThread[ Keys[children], acc ];

      threshold = paretoFraction * Last[acc];

      If[ removeBottomElementsQ,
        resChildren = KeyTake[ children, Keys @ Select[ acc, # <= threshold &] ],
        (* ELSE *)
        resChildren = KeyTake[ children, Keys @ Select[ acc, # >= threshold &] ]
      ];

      If[! (TrueQ[postfix === None] || TrueQ[postfix === Null]) && Length[resChildren] < Length[tr[[2]]] - 1,

        removeSum = Total @ Map[ #[$TrieValue] &, KeyDrop[tr[[2]], Prepend[ Keys[resChildren], $TrieValue] ] ];

        resChildren = Append[resChildren, postfix -> <|$TrieValue -> removeSum|>]
      ];

      tr[[1]] -> Join[KeyTake[tr[[2]], $TrieValue], resChildren]
    ];


(************************************************************)
(* Trie conversion related functions                        *)
(************************************************************)

Clear[TrieToRules];
SyntaxInformation[TrieToRules] = { "ArgumentsPattern" -> { _, _. } };
TrieToRules[tree_?TrieQ] := Block[{ORDER = 0}, TrieToRules[tree, 0, 0]];
TrieToRules[tree_, level_, order_] :=
    Block[{nodeRules, k, v},
      Which[
        tree === <||>, {},
        Keys[tree] === {$TrieValue}, {},
        True,
        k = First[Keys[tree]]; v = tree[k, $TrieValue];
        nodeRules =
            KeyValueMap[{{k, v}, {level, order}} -> {{#1, #2[$TrieValue]}, {level + 1, ORDER++}} &, KeyDrop[tree[k], $TrieValue]];
        Join[nodeRules,
          Flatten[
            MapThread[
              TrieToRules[<|#1|>, level + 1, #2] &, {Normal@
                KeyDrop[tree[k], $TrieValue], nodeRules[[All, 2, 2, 2]]}], 1]]
      ]
    ] /; TrieQ[tree];


Clear[GrFramed];
GrFramed[text_] :=
    Framed[text, {Background -> RGBColor[1, 1, 0.8],
      FrameStyle -> RGBColor[0.94, 0.85, 0.36], FrameMargins -> Automatic}];


Clear[TrieForm];
SyntaxInformation[TrieForm] = { "ArgumentsPattern" -> { _, OptionsPattern[] } };
Options[TrieForm] = Options[LayeredGraphPlot];
TrieForm[mytrie_?TrieQ, opts : OptionsPattern[]] :=
    LayeredGraphPlot[
      TrieToRules[mytrie],
      opts,
      VertexShapeFunction -> (Text[GrFramed[#2[[1]]], #1] &), PlotTheme -> "Classic" ];


Clear[TrieToJSON];
SyntaxInformation[TrieToJSON] = { "ArgumentsPattern" -> { _ } };
TrieToJSON[tr_?TrieQ] := TrieToJSON[First@Normal@tr];
TrieToJSON[tr_?TrieRuleQ] :=
    Block[{k = First@tr},
      {"key" -> k, "value" -> tr[[2]][$TrieValue],
        "children" -> Map[TrieToJSON, Normal[KeyDrop[tr[[2]], $TrieValue]]]}
    ];


Clear[TrieToListTrie];
SyntaxInformation[TrieToListTrie] = { "ArgumentsPattern" -> { _ } };
TrieToListTrie[tr_?TrieQ] := TrieToListTrie[First@Normal@tr] /. $TrieRoot -> {};
TrieToListTrie[tr_?TrieRuleQ] :=
    Block[{k = First@tr},
      Join[ {{k, tr[[2]][$TrieValue]}}, Normal @ Map[TrieToListTrie, Normal[KeyDrop[tr[[2]], $TrieValue]]] ]
    ];


(************************************************************)
(* TrieComparisonGrid                                       *)
(************************************************************)

Clear[TrieComparisonGrid];

SyntaxInformation[TrieComparisonGrid] = { "ArgumentsPattern" -> { _, OptionsPattern[] } };

SetAttributes[TrieComparisonGrid, HoldAll];

Options[TrieComparisonGrid] = Union[Options[Graphics], Options[Grid], {"NumberFormPrecision" -> 3}];

TrieComparisonGrid[trs_List, opts : OptionsPattern[]] :=
    Block[{graphOpts, gridOpts, nfp},
      graphOpts = Select[{opts}, MemberQ[Options[Graphics][[All, 1]], #[[1]]] &];
      gridOpts = Select[{opts}, MemberQ[Options[Grid][[All, 1]], #[[1]]] &];
      nfp = OptionValue["NumberFormPrecision"];
      Grid[{
        First @ Map[HoldForm, Inactivate[Hold[trs]], {2}],
        If[ Length[{graphOpts}] == 0,
          Map[TrieForm[#] /. {k_String, v_?NumericQ} :> {k, NumberForm[v, nfp]} &, trs],
          Map[TrieForm[#] /. {k_String, v_?NumericQ} :> {k, NumberForm[v, nfp]} /. (gr_Graphics) :> Append[gr, graphOpts] &, trs],
          Map[TrieForm[#] /. {k_String, v_?NumericQ} :> {k, NumberForm[v, nfp]} &, trs]
        ]
      }, gridOpts, Dividers -> All, FrameStyle -> LightGray]
    ];


(************************************************************)
(* Trie classify                                            *)
(************************************************************)

Clear[TrieClassify];

SyntaxInformation[TrieClassify] = { "ArgumentsPattern" -> { _, _, _., OptionsPattern[] } };

TrieClassify::notkey = "The second argument is not key in the trie: `1`.";

Options[TrieClassify] := {"Default" -> None, "VerifyKeyExistence" -> True};

TrieClassify[tr_?TrieQ, record_, opts : OptionsPattern[]] :=
    TrieClassify[tr, record, "Decision", opts] /; FreeQ[{opts}, "Probability" | "TopProbabilities"];

TrieClassify[tr_?TrieQ, record_, "Decision", opts : OptionsPattern[]] :=
    First@Keys@TrieClassify[tr, record, "Probabilities", opts];

TrieClassify[tr_?TrieQ, record_, "Probability" -> class_, opts : OptionsPattern[]] :=
    Lookup[TrieClassify[tr, record, "Probabilities", opts], class, 0];

TrieClassify[tr_?TrieQ, record_, "TopProbabilities", opts : OptionsPattern[]] :=
    Select[TrieClassify[tr, record, "Probabilities", opts], # > 0 &];

TrieClassify[tr_?TrieQ, record_, "TopProbabilities" -> n_Integer, opts : OptionsPattern[]] :=
    Take[TrieClassify[tr, record, "Probabilities", opts], UpTo[n]];

TrieClassify[tr_?TrieQ, record_, "Probabilities", opts : OptionsPattern[]] :=
    Block[{res,
      dval = OptionValue[TrieClassify, "Default"],
      verifyKeyQ = TrueQ[OptionValue[TrieClassify, "VerifyKeyExistence"]]},

      If[ verifyKeyQ && !TrieKeyExistsQ[ tr, record ],
        Message[TrieClassify::notkey, record];
        Return[$Failed]
      ];

      res = TrieSubTrie[tr, record];
      If[ TrueQ[res === $Failed], Return[$Failed] ];
      If[ Length[res] == 0,
        <|dval -> 0|>,
        (* ELSE *)
        res = ReverseSort[ Association[ Rule @@@ TrieLeafProbabilities[res] ] ];
        res / Total[res]
      ]
    ];

TrieClassify[tr_?TrieQ, records : (_Dataset | {_List..}), "Decision", opts : OptionsPattern[]] :=
    First @* Keys @* TakeLargest[1] /@ TrieClassify[tr, records, "Probabilities", opts];

TrieClassify[tr_?TrieQ, records : (_Dataset | {_List..}), "Probability" -> class_, opts : OptionsPattern[]] :=
    Map[Lookup[#, class, 0]&, TrieClassify[tr, records, "Probabilities", opts] ];

TrieClassify[tr_?TrieQ, records : (_Dataset | {_List..}), "TopProbabilities", opts : OptionsPattern[]] :=
    Map[ Select[#, # > 0 &]&, TrieClassify[tr, records, "Probabilities", opts] ];

TrieClassify[tr_?TrieQ, records : (_Dataset | {_List..}), "TopProbabilities" -> n_Integer, opts : OptionsPattern[]] :=
    Map[TakeLargest[#, UpTo[n]]&, TrieClassify[tr, records, "Probabilities", opts] ];

TrieClassify[tr_?TrieQ, records : (_Dataset | {_List..}), "Probabilities", opts : OptionsPattern[] ] :=
    Block[{clRes, classLabels, stencil},

      clRes = Map[ TrieClassify[tr, #, "Probabilities", opts] &, Normal@records ];

      classLabels = Union[Flatten[Normal[Keys /@ clRes]]];

      stencil = AssociationThread[classLabels -> 0];

      KeySort[Join[stencil, #]] & /@ clRes
    ];

TrieClassify[___] := $Failed;

End[];
EndPackage[];
