pub fn base64_encode(input: ByteArray) -> ByteArray {
    let BASE64_TABLE: Array<ByteArray> = array![
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I",
        "J",
        "K",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S",
        "T",
        "U",
        "V",
        "W",
        "X",
        "Y",
        "Z",
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z",
        "0",
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "+",
        "/",
    ];
    let mut output: ByteArray = "";

    let mut i = 0;
    loop {
        if i >= input.len() {
            break output.clone();
        }

        let b0 = input.at(i).unwrap();
        let b1 = if i + 1 < input.len() {
            input.at(i + 1).unwrap()
        } else {
            0
        };
        let b2 = if i + 2 < input.len() {
            input.at(i + 2).unwrap()
        } else {
            0
        };

        let triple: u32 = (left_shift(b0.into(), 16).try_into().unwrap())
            | (left_shift(b1.into(), 8).try_into().unwrap())
            | b2.into();

        output
            .append(BASE64_TABLE.at(((right_shift(triple.into(), 18)) & 0x3F).try_into().unwrap()));
        output
            .append(BASE64_TABLE.at(((right_shift(triple.into(), 12)) & 0x3F).try_into().unwrap()));
        output
            .append(
                if i + 1 < input.len() {
                    BASE64_TABLE.at(((right_shift(triple.into(), 6)) & 0x3F).try_into().unwrap())
                } else {
                    @"="
                },
            );
        output
            .append(
                if i + 2 < input.len() {
                    BASE64_TABLE.at((triple & 0x3F).into())
                } else {
                    @"="
                },
            );

        i += 3;
    }
}

pub fn multi_div(num: u256, div: u256) -> u256 {
    let mut result = num;
    let mut index = 1;
    while (index < div) {
        result = result / 10;
        index += 1;
    };
    result
}

pub fn left_shift(input: u256, count: u256) -> u256 {
    let mut index = 0;
    let mut result = input;
    loop {
        if index == count {
            break result;
        }
        result = result * 2;
        index += 1;
    }
}

pub fn right_shift(num: u256, shift_by: u256) -> u256 {
    if shift_by == 0 {
        return num;
    }

    let result = num / (left_shift(1, shift_by));
    result
}

pub fn uint_to_str(num: u256) -> ByteArray {
    if num == 0 {
        return "0";
    }

    let mut i = num.clone();
    let mut j = num.clone();
    let mut length = 0;
    while (i != 0) {
        length += 1;
        i /= 10;
    };

    let mut result: ByteArray = "";
    let mut k = length;
    while (k != 0) {
        k -= 1;
        let temp: u8 = (j % 10).try_into().unwrap();

        result.append(@format!("{}", temp));
        j = j / 10;
    };

    return result.rev();
}
