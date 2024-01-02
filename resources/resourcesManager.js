const fs = require('fs');
const { extractFont, createImageFromPath } = require('./imageProcess.js');

const structDefineFile = '../src/struct_define.v';
const romDataOutputFile = 'rom';
const resourcesDefineFile = '../src/resources_define.v';
const imageBitdepth = 16;
const resources = [
    { path: 'sphere.png', toWidth: 16, padding: true },
    { path: 'brick.png', toWidth: 16 },
    // { path: 'heart.png', toWidth: 7 },
    // { path: 'DVD_logo.png', toWidth: 32 },
    // { path: 'shoto.png', toWidth: 32 },
];
const structs = [
    {
        name: 'gameObjs',
        array: true,
        maxLen: 5 + 32,
        propties: [
            { name: 'objTag', size: 3 },
            { name: 'objX', size: 12 },
            { name: 'objY', size: 12 },
            { name: 'objW', size: 10 },
            { name: 'objH', size: 10 },
            { name: 'objColor', size: 16 },
            { name: 'objImgId', size: 3, mask: true },
            { name: 'objImgScale', size: 2 }
        ]
    }
];
const fontFile = {
    fontPath: 'fonts/PublicPixel.ttf',
    characterHeight: 7,
    // fontPath: 'fonts/mini-pixel-7.regular.ttf',
    // characterHeight: 12,
};
const randomSettings = {
    randomLen: 8,
};

(async function () {
    // Struct define setup
    createStructDefine();


    const defineLines = [];
    // Rom define setup
    await createRom(0, defineLines);
    await createFontRom(defineLines);
    createRandom(defineLines);

    // Save define file
    fs.writeFileSync(resourcesDefineFile, defineLines.join('\n'));
})();

function createStructDefine() {
    const defineLines = [];
    for (const struct of structs) {
        defineLines.push(`// struct ${struct.name}`);
        let itemOff = 0;
        const getter = [];
        for (const prop of struct.propties) {
            defineLines.push(`\`define ${prop.name}Size ${prop.size}`);
            getter.push(`\`define ${prop.name}(index) ` +
                `[(index)*\`${struct.name}Size${itemOff ? '+' + itemOff : ''}+:\`${prop.name}Size]`
            );
            // Item prop mask
            if (prop.mask)
                defineLines.push(`\`define ${prop.name}Mask ${prop.size}'b${((1 << prop.size) - 1).toString(2)}`);


            itemOff += prop.size;
        }
        getter.push(`\`define ${struct.name}Size ${itemOff}`);
        getter.push(`\`define ${struct.name}MaxLen ${struct.maxLen}`);
        if (struct.array) {
            const totalBit = itemOff * struct.maxLen;
            getter.push(`\`define ${struct.name}Init reg [${totalBit - 1}:0] ${struct.name}=${totalBit}'d0`);
            console.log(`${struct.name} array: ${totalBit} bits`);
        }
        defineLines.push(...getter);
    }

    fs.writeFileSync(structDefineFile, defineLines.join('\n'));
}

async function createRom(romIndex, defineLines) {
    let itemIndex = 0;
    let itemOffset = [0];
    let romData = [];
    let romDataSizeBit = 0;

    // Image res
    defineLines.push(`\`define imageBitdepth ${imageBitdepth}`);
    defineLines.push('`define imageW(index) ((`imgWidth>>((index)<<4))&16\'hFFFF)');
    defineLines.push('`define imageH(index) ((`imgHeight>>((index)<<4))&16\'hFFFF)');
    defineLines.push('`define image(index,x,y) ' +
        `[((((\`itemStart>>((index)*20))&20'hFFFFF)+((x)+(y)*\`imageW(index)))<<4)+:${imageBitdepth}]`);

    let imgWidth = [], imgHeight = [];
    for (const resource of resources) {
        const imageData = await createImageFromPath(resource.path, resource.toWidth, resource.padding, true);
        const hexData = imageData.imageHexData;

        romDataSizeBit += hexData.reduce((a, b) => a + b.length * 4, 0);
        const itemData = hexData.join('');
        romData.unshift(itemData);
        imgWidth.push(imageData.imageWidth);
        imgHeight.push(imageData.imageHeight);
        defineLines.push(`// item${itemIndex}(${resource.path}): ${imageData.imageWidth}x${imageData.imageHeight}`);
        console.log(`${resource.path} ${imageData.imageWidth}x${imageData.imageHeight}`);

        if (itemIndex + 1 < resources.length)
            itemOffset.push(itemOffset[itemOffset.length - 1] + (itemData.length >> 2));
        itemIndex++;
    }
    itemOffset.reverse();
    defineLines.push(`\`define itemStart ${itemOffset.length * 20}'h` + itemOffset.map(i => i.toString(16).padStart(5, '0')).join(''));
    imgWidth.reverse();
    defineLines.push(`\`define imgWidth ${imgWidth.length << 4}'h` + imgWidth.map(i => i.toString(16).padStart(4, '0')).join(''));
    imgHeight.reverse();
    defineLines.push(`\`define imgHeight ${imgHeight.length << 4}'h` + imgHeight.map(i => i.toString(16).padStart(4, '0')).join(''));

    defineLines.push(`\`define ${romDataOutputFile}${romIndex}ItemCount ${itemIndex}`);
    defineLines.push(`\`define ${romDataOutputFile}${romIndex}Length ${romDataSizeBit}`);
    defineLines.push('');

    fs.writeFileSync(`${romDataOutputFile}${romIndex}.hex`, romData.join(''));
    console.log(`Save ${romDataOutputFile}${romIndex}.hex: ${romDataSizeBit} bits\n`);
}

async function createFontRom(defineLines) {
    const cacheFolder = 'cache';
    const fontOutFile = 'font'
    if (!fs.existsSync(cacheFolder))
        fs.mkdirSync(cacheFolder, true);

    let fontDataSizeBit = 0;
    const { hexResult, characterOffsets, charMaxWidth } =
        await extractFont(fontFile.fontPath, cacheFolder, fontFile.characterHeight);

    fontDataSizeBit = hexResult.reduce((a, b) => a + b.length, 0);
    defineLines.push(`\`define ${fontOutFile}Length ${fontDataSizeBit}`);
    defineLines.push(`\`define ${fontOutFile}CharHeight ${fontFile.characterHeight}`);
    defineLines.push(`\`define ${fontOutFile}CharMaxWidth ${charMaxWidth}`);
    const dataWidth = hexResult.length > 0 ? hexResult[0].length : 0;
    const charWidth = [];
    const digitStart = [], letterStart = [];
    itemOffset = [];
    itemIndex = 0;
    for (const character of characterOffsets) {
        let charCode = character.char.charCodeAt(0);
        if (charCode >= 48 && charCode <= 57)
            digitStart.push(itemIndex);
        else if (
            charCode >= 65 && charCode <= 90 ||
            charCode >= 97 && charCode <= 122)
            letterStart.push(itemIndex);
        else
            defineLines.push(`\`define fontOff_${charCode} ${itemIndex} // ${character.char}`);
        charWidth.push(character.width);
        itemOffset.push(character.offset);
        itemIndex++;
    }
    digitStart.reverse();
    defineLines.push(`\`define fontDigitStart ${digitStart.length << 3}'h` + digitStart.map(i => i.toString(16).padStart(2, '0')).join(''));
    defineLines.push('`define fontDigitOff(digit) ((`fontDigitStart>>((digit)<<3))&8\'hFF)');

    letterStart.reverse();
    defineLines.push(`\`define fontLetterStart ${letterStart.length << 3}'h` + letterStart.map(i => i.toString(16).padStart(2, '0')).join(''));
    defineLines.push('`define fontLetterOff(letter) (letter>"Z"?((`fontLetterStart>>((letter-71)<<3))&8\'hFF):((`fontLetterStart>>((letter-"A")<<3))&8\'hFF))');

    itemOffset.reverse();
    defineLines.push(`\`define fontCharStart ${itemOffset.length * 20}'h` + itemOffset.map(i => i.toString(16).padStart(5, '0')).join(''));
    defineLines.push(`\`define fontChar(index,x,y) [(y)*${dataWidth}+(x)+((\`fontCharStart>>((index)*20))&20'hFFFFF)+:1]`);

    charWidth.reverse();
    defineLines.push(`\`define fontCharWidth ${charWidth.length << 4}'h` + charWidth.map(i => i.toString(16).padStart(4, '0')).join(''));
    defineLines.push('`define fontCharW(index) ((`fontCharWidth>>((index)<<4))&16\'hFFFF)');

    defineLines.push('');
    hexResult.reverse();
    fs.writeFileSync(`${fontOutFile}.hex`, hexResult.join(''));
    console.log(`Save ${fontOutFile}.hex: ${fontDataSizeBit} bits\n`);
}

function createRandom(defineLines) {
    defineLines.push(`\`define randomLen ${randomSettings.randomLen}`);

    const randomList = [];
    for (let i = 0; i < randomSettings.randomLen / 4; i++)
        randomList.push(((Math.random() * 4) | 0).toString(16));

    defineLines.push(`\`define randomList ${randomList.length * 4}'h${randomList.join('')}`);
    defineLines.push('');
}

function firstUpper(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}