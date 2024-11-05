# Fix review

## FBP

1. FBP-1
    Partially fixed. Coverage is 77 % by lines, can be improved.
2. FBP-2
    Fixed.
3. FBP-3
    Not fixed. Fixed on this branch.
4. FBP-4
    Fixed.
5. FBP-5
    Not fixed. Fixed on this branch.
6. FBP-6
    NatSpec not added.
7. FBP-7
    Still uses old version of OZ.

## Security assumptions

1. SA-1
    Not fixed. still uses the same.
2. SA-2
    Partially fixed. Now fees can be setted to "blocking" value after deployment.
3. SA-3
    Not fixed.
4. SA-4
    Fixed.
5. SA-5
    fixed. Added WL check to the contracts.

## Optimizations

1. OPT-1
    Fixed.
2. OPT-2
    Fixed.
3. OPT-3
    Logic changed here. Confirm that it's correct.
4. OPT-4
    Fixed.
5. OPT-5
    Partially fixed.
6. OPT-6
   Not fixed. Needed comment here.

## Questions and Suggestions

1. Нa фоне с предыдущими контрактами мне кажеться резонно предусмотреть возможность апргрейда, но если не планируется это, можно оставить текущие контракты как есть.
2. Если планируется деплой множества NFT то стоит рассмотреть minimal Proxy паттерн.