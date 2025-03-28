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

        let triple: u32 = (left_shift(b0.try_into().unwrap(), 16))
            | (left_shift(b1.try_into().unwrap(), 8))
            | b2.try_into().unwrap();

        output.append(BASE64_TABLE.at(((right_shift(triple, 18)) & 0x3F).into()));
        output.append(BASE64_TABLE.at(((right_shift(triple, 12)) & 0x3F).into()));
        output
            .append(
                if i + 1 < input.len() {
                    BASE64_TABLE.at(((right_shift(triple, 6)) & 0x3F).into())
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

fn left_shift(input: u32, count: u32) -> u32 {
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

fn right_shift(num: u32, shift_by: u32) -> u32 {
    if shift_by == 0 {
        return num;
    }

    let result = num / (left_shift(1, shift_by));
    result
}

