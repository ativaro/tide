# Eight first solutions in task order

```tide
rule notiz event:i > &ii
state cursor:i=3 mark:i=7
when eq event 1 -> cursor=set + cursor 2, mark=keep
when eq event 3 -> cursor=keep, mark=set cursor
when eq event 2 -> cursor=set mark, mark=set cursor
when eq event 4 -> cursor=reset, mark=keep
else -> cursor=keep, mark=keep
out pair cursor mark
```

```tide
plaetze available:i booked:b event:i > &ib
let same pair available booked
if eq event 3
  if booked same if > available 0 pair + available -1 true same
if eq event 4 pair if booked + available 1 available false
if eq event 1 pair available false
if eq event 2 pair 2 false same
```

```tide
rule spiel event:i > &ii
state score:i=4 bonus:i=1
when eq event 2 -> score=keep, bonus=set + bonus 2
when eq event 3 -> score=set + score bonus, bonus=reset
when eq event 1 -> score=reset, bonus=keep
when if eq event 4 > bonus score false -> score=keep, bonus=set score
else -> score=keep, bonus=keep
out pair score bonus
```

```tide
timer left:i paused:b event:i > &ib
let same pair left paused
if eq event 2 if paused same pair + left -1 eq left 1
if eq event 1 pair if eq left 0 3 left false
if eq event 3 pair left true
if eq event 4 pair 3 true same
```

```tide
karte position:i saved:i event:i > &ii
if eq event 1 pair + position 2 saved
if eq event 4 pair position position
if eq event 3 pair saved position
if eq event 2 pair 3 saved
pair position saved
```

```tide
rule karten event:i > &ib
state credits:i=2 reserved:b=false
when if eq event 2 if reserved false > credits 0 false -> credits=set + credits -1, reserved=set true
when if eq event 3 reserved false -> credits=set + credits 1, reserved=reset
when eq event 4 -> credits=keep, reserved=reset
when eq event 1 -> credits=reset, reserved=reset
else -> credits=keep, reserved=keep
out pair credits reserved
```

```tide
konto total:i pending:i event:i > &ii
if eq event 1 pair total + pending 2
if eq event 4 pair + total pending 1
if eq event 2 pair 4 pending
if eq event 3 pair total if > pending total total pending
pair total pending
```

```tide
rule etappe event:i > &ib
state steps:i=3 stopped:b=true
when if eq event 3 stopped false -> steps=keep, stopped=keep
when eq event 3 -> steps=set + steps -1, stopped=set eq steps 1
when if eq event 2 eq steps 0 false -> steps=reset, stopped=set false
when eq event 2 -> steps=keep, stopped=set false
when eq event 1 -> steps=keep, stopped=set true
when eq event 4 -> steps=reset, stopped=reset
else -> steps=keep, stopped=keep
out pair steps stopped
```
