# EDUCATION.md — Bonds (price/yield inverse, coupon, maturity, duration)

> What this game teaches: the single most counter-intuitive fact in finance — **bond prices move
> opposite to interest rates** — and the follow-on that **longer bonds move more** (duration /
> interest-rate risk). It is not narrated over the top of the game; it IS the game. Every trade you make
> is a bet on which way the rate goes next, and the price reacts the exact opposite way, every frame.

- **Scale:** `BioScale.financial`.
- **Game:** `bonds`.
- **Sibling game on this scale:** `market_trader` (equities — buy-low/sell-high on a single price).
  Bonds is the *fixed-income* counterpart: the price isn't a free-floating ticker, it is **derived** from
  a published interest rate by a fixed formula, so the inverse relationship is mechanical and inevitable.

---

## 1. What a bond actually is

A bond is a **loan you can trade**. When you buy a $100 bond paying a 4% coupon for 10 years, you are
lending $100 and the issuer promises:
- a fixed **coupon** — $4 every year (4% of the $100 **face/par** value), and
- your **$100 face value back** at **maturity** (year 10).

Those cash flows are **fixed at issue**. They never change. The coupon is 4% forever; the face is $100
forever. What *does* change is what that fixed stream is **worth to someone else today** — its market
**price** — and that is set by current interest rates.

| Term | Meaning | In the game |
|---|---|---|
| **Face / par** | The amount repaid at maturity | $100 for every bond (`_kFace`) |
| **Coupon** | The fixed annual interest, % of face | 4.0%–4.5%, shown on each bond badge |
| **Maturity** | Years until the face is repaid | 2Y / 5Y / 10Y / 30Y |
| **Yield / rate** | The current market interest rate used to value it | the moving INTEREST RATE ticker |
| **Price** | What the bond trades for right now | the live number on each bond row |

---

## 2. The price/yield inverse — why it MUST be true

A bond's price is the **present value** of its fixed cash flows, discounted at today's market rate `y`:

```
price = Σ  coupon / (1 + y)^t   +   face / (1 + y)^N
        t=1..N
```

This is exactly the formula the game runs every frame (`_price`). Read it as the lesson:

- **Rates rise → price falls.** A bigger `y` makes every `(1 + y)^t` denominator bigger, so every future
  dollar is worth less today, so the whole sum shrinks. Higher rate, lower price. **Always.**
- **Intuition without the algebra:** if new bonds are issued paying 8% and you're holding one that only
  pays 4%, nobody will buy yours at full price — they'd rather have the 8% one. To sell, you must **drop
  your price** until your 4% bond yields a competitive return to its new buyer. Your old bond got *cheaper*
  precisely *because* rates went *up*.
- **Rates fall → price rises.** Your 4% bond now looks generous next to new 2% bonds, so buyers pay a
  **premium** for it.

The game's rate panel spells this out live: `RATES ▲ ⇒ PRICES ▼` flips to `RATES ▼ ⇒ PRICES ▲` the
instant the rate trend turns. The RATE line and the PRICE line on the chart are mirror images — because
the price line is literally computed *from* the rate line.

---

## 3. Duration — why LONGER bonds move MORE

Two bonds, same 1% jump in rates. The 2Y barely flinches; the 30Y can lurch many percent. Why?

A long bond has **more future cash flows, further out in time**, and the discounting penalty
`(1 + y)^t` compounds harder the larger `t` is. Re-pricing 30 years of payments at a higher rate moves
the total far more than re-pricing 2 years of payments. This sensitivity has a name: **duration**. As a
rule of thumb, a 1% rate rise drops a bond's price by roughly its duration in percent — so a ~17-year-
duration long bond loses ~17% on a 1% rate jump, while a 2-year bond loses ~2%.

The game shows this directly: every bond row carries a live **`rate +1% ⇒ −X%`** gauge (`_sensitivity`),
and the number is small for the 2Y and large for the 30Y. That gauge *is* duration, made visible. The
30Y unlocking late in the round is the difficulty spike — it's where the biggest profits and the most
painful losses both live. This is **interest-rate risk**: holding long bonds means holding big exposure
to rate moves you can't control.

---

## 4. How to actually win (and what each move teaches)

- **Buy long bonds when you expect rates to FALL.** Falling rates push prices up, and long bonds rise
  most — maximum gain. (Buy the dip before the rally.)
- **Dump long bonds before rates RISE.** Rising rates crush prices, and long bonds fall most — get out,
  or hide in short bonds whose prices barely move.
- **Short bonds are the safe harbour.** Low duration = low reward but low risk. When you're unsure which
  way rates go, the 2Y protects your cash.
- **Coupon is your floor.** A higher coupon delivers more cash sooner, which slightly cushions the price
  fall — part of why the shorter bonds here also carry the higher coupon.

The skill the game trains is reading the rate trend and matching your **maturity to your conviction**:
size up in long bonds when you're sure, retreat to short bonds when you're not.

---

## 5. Vocabulary, mapped to the mechanic

| Real concept | In the game |
|---|---|
| Price/yield inverse relationship | RATE line and PRICE line move opposite; `RATES ▲ ⇒ PRICES ▼` callout |
| Present value / discounting | `_price` = PV of coupons + face at the live rate |
| Coupon | Fixed % on each bond badge; the annual cash the bond pays |
| Maturity | The 2Y / 5Y / 10Y / 30Y ladder |
| Duration / interest-rate risk | The `rate +1% ⇒ −X%` gauge; longer bonds swing harder |
| Capital gain/loss from rate moves | Realized P&L when you sell above/below your average cost |
| Reaching for yield vs safety | Long bonds (high reward/risk) vs short bonds (safe harbour) |

---

## Association verdict

**Strong tie to the financial scale.** You cannot post a high score without internalising the price/yield
inverse and the duration ladder: profit comes from buying the *right maturity* before the rate moves the
*right way*, and the game punishes holding the long bond into a rate spike exactly the way the real market
does. Where the sibling `market_trader` teaches the *behaviour* of a free-floating price (greed, timing,
volatility), Bonds teaches the *structure* underneath fixed income — that a bond's price isn't a mood, it
is arithmetic on the interest rate, and that arithmetic runs against you when rates rise.
