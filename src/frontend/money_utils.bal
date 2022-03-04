// IsValid checks if specified value has a valid units/nanos signs and ranges.
isolated function isValid(Money m) returns boolean {
    return signMatches(m) && validNanos(m.nanos);
}

isolated function signMatches(Money m) returns boolean {
    return m.nanos == 0 || m.units == 0 || (m.nanos < 0) == (m.units < 0);
}

isolated function validNanos(int nanos) returns boolean {
    return -999999999 <= nanos && nanos <= +999999999;
}

// IsZero returns true if the specified money value is equal to zero.
isolated function isZero(Money m) returns boolean {
    return m.units == 0 && m.nanos == 0;
}

// IsPositive returns true if the specified money value is valid and is
// positive.
isolated function isPositive(Money m) returns boolean {
    return isValid(m) && m.units > 0 || (m.units == 0 && m.nanos > 0);
}

// IsNegative returns true if the specified money value is valid and is
// negative.
isolated function isNegative(Money m) returns boolean {
    return isValid(m) && m.units < 0 || (m.units == 0 && m.nanos < 0);
}

// AreSameCurrency returns true if values l and r have a currency code and
// they are the same values.
isolated function areSameCurrency(Money l, Money r) returns boolean {
    return l.currency_code == r.currency_code && l.currency_code != "";
}

// AreEquals returns true if values l and r are the equal, including the
// currency. This does not check validity of the provided values.
isolated function areEquals(Money l, Money r) returns boolean {
    return l.currency_code == r.currency_code &&
l.units == r.units && l.nanos == r.nanos;
}

// Negate returns the same amount with the sign negated.
isolated function negate(Money m) returns Money {
    return {
        units: -m.units,
        nanos: -m.nanos,
        currency_code: m.currency_code
    };
}

// Sum adds two values. Returns an error if one of the values are invalid or
// currency codes are not matching (unless currency code is unspecified for
// both).
isolated function sum(Money l, Money r) returns Money {

    int nanosMod = 1000000000;

    int units = l.units + r.units;
    int nanos = l.nanos + r.nanos;

    if (units == 0 && nanos == 0) || (units > 0 && nanos >= 0) || (units < 0 && nanos <= 0) {
        // same sign <units, nanos>
        units += nanos / nanosMod;
        nanos = nanos % nanosMod;
    } else {
        // different sign. nanos guaranteed to not to go over the limit
        if units > 0 {
            units = units - 1;
            nanos += nanosMod;
        } else {
            units = units + 1;
            nanos -= nanosMod;
        }
    }

    return {
        units: units,
        nanos: nanos,
        currency_code: l.currency_code
    };
}

// MultiplySlow is a slow multiplication operation done through adding the value
// to itself n-1 times.
isolated function multiplySlow(Money m, int n) returns Money {
    int t = n;
    Money out = m;
    while t > 1 {
        out = sum(out, m);
        t = t - 1;
    }
    return out;
}

isolated function renderMoney(Money money) returns string {
    return currencyLogo(money.currency_code) + money.units.toString() + "." + (money.nanos / 10000000).toString();
}

isolated function currencyLogo(string code) returns string {
    map<string> logos = {
        "USD": "$",
        "CAD": "$",
        "JPY": "¥",
        "EUR": "€",
        "TRY": "₺",
        "GBP": "£"
    };
    return logos.get(code);
}
