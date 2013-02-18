%% Copyright (c) 2008-2009 
%% Pablo Polvorin <ppolv@jabberes.org> [http://ppolv.wordpress.com]
%% Jacob Vorreuter <jacob.vorreuter@gmail.com>
%% Nakai Ryosuke <nakai@voluntas.net>
%% 
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use,
%% copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following
%% conditions:
%% 
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%% 
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.
%%
%% @doc Some core xpath functions that can be used in xpath expressions
%% created on 2008-05-07
-module(mochiweb_xpath_functions).

-export([default_functions/0]).

%% Default functions.
%% The format is: {FunctionName, fun(), FunctionSignature}
%% @type FunctionName = atom()
%% @type FunctionSignature = [XPathType]
%% @type XPathType = node_set | string | number | boolean
%% 
%% The engine is responsable of calling the function with
%% the correct arguments, given the function signature. 
default_functions() ->
    [
        {'count',fun count/2,[node_set]},
        {'name',fun 'name'/2,[node_set]},
        {'starts-with', fun 'starts-with'/2,[string,string]},
        {'substring', fun substring/2,[string,number,number]},
        {'sum', fun sum/2,[node_set]},
        {'string-length', fun 'string-length'/2,[string]},
		{'string', fun to_string/2, [node_set]},
		{'last', fun last/2, [node_set]},
        {'contains', fun contains/2,[string,string]},
        {'concat', fun concat/2,[string,string,string]}
    ].


%% @doc Function: number count(node-set) 
%%      The count function returns the number of nodes in the 
%%      argument node-set.
count(_Ctx,[NodeList]) ->
    length(NodeList).

%% @doc Function: string name(node-set?)
'name'(_Ctx,[[{Tag,_,_}|_]]) ->
    Tag.

%% @doc Function: boolean starts-with(string, string) 
%%      The starts-with function returns true if the first argument string
%%      starts with the second argument string, and otherwise returns false.
'starts-with'(_Ctx,[Left,Right]) ->
    Size = size(Right),
    case Left of
        <<Right:Size/binary,_/binary>> -> true;
        _ -> false
    end.

%% @doc Function: string substring(string, number, number?) 
%%      The substring function returns the substring of the first argument 
%%      starting at the position specified in the second argument with length
%%      specified in the third argument
substring(_Ctx,[String,Start,Length]) when is_binary(String)->
    Before = Start -1,
    After = size(String) - Before - Length,
    case (Start + Length) =< size(String) of
        true ->
            <<_:Before/binary,R:Length/binary,_:After/binary>> = String,
            R;
        false ->
            <<>>
    end.

%% @doc Function: number sum(node-set) 
%%      The sum function returns the sum, for each node in the argument 
%%      node-set, of the result of converting the string-values of the node
%%      to a number.
sum(_Ctx,[Values]) ->
    lists:sum(lists:map(fun  mochiweb_xpath_utils:number_value/1,Values)).

%% @doc Function: number string-length(string?) 
%%      The string-length returns the number of characters in the string 
%%      TODO: this isn't true: currently it returns the number of bytes
%%            in the string, that isn't the same 
'string-length'(_Ctx,[String]) ->
    size(String).

to_string(_Ctx,[Values]) ->
	List = lists:foldr(
		fun (Bin, Acc) when is_binary(Bin) -> [Bin|Acc];
			({_,_,_}=Node, Acc) -> [mochiweb_html:to_html(Node)|Acc]
		end, [], Values),
	binary_to_list(iolist_to_binary(List)).
	
last(_Ctx, [Values]) -> 
    lists:last(Values).
	
%% @doc Function: boolean contains(string, string)
%%      The contains function returns true if the second string is contained
%%      within the first.
%%      TODO: not Unicode safe.
contains(_Ctx,[Haystack,Needle]) ->
    string:str(binary_to_list(Haystack), binary_to_list(Needle)) /= 0.

%% @doc Function: string concat(string...)
%%      Returns the concatenation of all given strings.
concat(_Ctx,Strs) ->
    lists:foldr(
        fun(A,B) -> <<A/binary, B/binary>> end,
        <<>>,
        Strs
    ).
