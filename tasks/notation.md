# Token measurement for model notation

Measured as of 16 November 2026 with tiktoken 0.14.0. Counted was the complete displayed source code without trailing newline, Markdown, or chat wrapper. Both encodings come from the same tokenizer family. There was no model call. [tiktoken](https://github.com/openai/tiktoken)

| Function | Encoding | Draft 0.1 | 0.1 minified | Draft 0.2 |
|---|---|---:|---:|---:|
| twice | `o200k_base` | 16 | 14 | 10 |
| twice | `cl100k_base` | 16 | 14 | 10 |
| higher | `o200k_base` | 26 | 21 | 14 |
| higher | `cl100k_base` | 26 | 21 | 14 |
| maximum | `o200k_base` | 105 | 75 | 39 |
| maximum | `cl100k_base` | 105 | 74 | 39 |

For the measurement program, the source code volume drops from 105 to 39 tokens (63 %). Against the minified version of the earlier draft, the savings amount to 47 to 48 %. An additional control uses the same short names and new operations as 0.2 in a minified parenthesized representation. It occupies 44 tokens in both encodings. Against this control form, the new format saves five tokens (11 %). Thus, the larger part of the total gain lies in representing the program with fewer explicit steps and shorter names. The influence of individual operations was not isolated here.

For language selection, reference, input context, changes, repairs, success, and time are also to be measured. The three short, handwritten examples show the size of a specific representation. Statistical statements about model performance or runtime require their own experiments.

## Costs of more meaningful names

In a second measurement, we exclusively swapped the five local names. From `b k x n p`, `best row line value previous` were substituted at the same locations. The current programs are in the [Language Draft](../SPEC.md). Both encodings yielded the same values.

| Full Program | Short Names | Meaningful Names |
|---|---:|---:|
| Maximum | 39 Tokens | 39 Tokens |
| Maximum with first occurrence | 46 Tokens | 46 Tokens |

For these two programs, we can directly express the meaning of the values without consuming additional tokens. Whether a model makes fewer domain-specific errors with this is open.

## Repeat counting

For each string shown below, the following counting path applies. The minified versions are fully specified so that whitespace and token boundaries remain reproducible.

```python
import tiktoken

for name in ("o200k_base", "cl100k_base"):
    print(name, len(tiktoken.get_encoding(name).encode(source)))
```

## twice

Draft 0.1

```lisp
(fn twice ((x I64)) I64 (return (add x x)))
```

Minified Draft 0.1

```lisp
(fn twice((x I64))I64(return(add x x)))
```

Draft 0.2

```tide
twice x:i > i
+ x x
```

## higher

Draft 0.1

```lisp
(fn higher ((a I64) (b I64)) I64 (return (if (gt a b) a b)))
```

Minified Draft 0.1

```lisp
(fn higher((a I64)(b I64))I64(return(if(gt a b)a b)))
```

Draft 0.2

```tide
higher a:i b:i > i
if > a b a b
```

## maximum

Draft 0.1

```lisp
(fn main ((input ReadText)) (Option I64)
  (var best (none I64))
  (for (nr line) (lines (read_text input))
    (let n
      (match (to_i64 line)
        (none (fail "invalid_integer" nr))
        ((some value) value)))
    (set best
      (some (match best
        (none n)
        ((some old) (if (gt n old) n old))))))
  (return best))
```

Minified Draft 0.1

```lisp
(fn main((input ReadText))(Option I64)(var best(none I64))(for(nr line)(lines(read_text input))(let n(match(to_i64 line)(none(fail "invalid_integer" nr))((some value)value)))(set best(some(match best(none n)((some old)(if(gt n old)n old))))))(return best))
```

Draft 0.2

```tide
main input:r > ?i
fold lines read input nil i b k x
let n need int x "invalid_integer" k
some case b n p if > n p n p
```

## Control with the same operations as 0.2

Minified bracket form of the measurement report program.

```lisp
(main((input r))(? i)(fold(lines(read input))(nil i)b k x(let n(need(int x)"invalid_integer" k)(some(case b n p(if(> n p)n p))))))
```
