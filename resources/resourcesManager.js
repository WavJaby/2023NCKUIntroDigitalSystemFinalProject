const fs = require('fs');
const { createImage, createImageFromPath } = require('./imageProcess.js');

const structDefineFile = '../src/struct_define.v';
const romDataOutputFile = 'rom';
const resourcesDefineFile = '../src/resources_define.v';
const imageBitdepth = 16;
const resources = [
    { path: 'sphere.png', toWidth: 16, padding: true },
    { path: 'brick.png', toWidth: 16 },
    // { path: 'DVD_logo.png', toWidth: 32 },
    // { path: 'shoto.png', toWidth: 32 },
];
const structs = [
    {
        name: 'gameObjs',
        array: true,
        maxLen: 50,
        propties: [
            { name: 'objX', size: 12 },
            { name: 'objY', size: 12 },
            { name: 'objW', size: 12 },
            { name: 'objH', size: 12 },
            { name: 'objTag', size: 4 },
            { name: 'objColor', size: 16 },
            { name: 'objImgId', size: 4, mask: true },
            { name: 'objImgScale', size: 2 }
        ]
    }
];

(async function () {
    // Struct define setup
    createStructDefine();

    // Rom define setup
    await createRom(0);
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

async function createRom(romIndex) {
    let itemIndex = 0;
    let itemOffset = [0];
    let romData = [];
    let romDataSizeBit = 0;

    const defineLines = [];
    defineLines.push(`\`define imageBitdepth ${imageBitdepth}`);
    defineLines.push('`define imageW(index) ((`imgWidth>>((index)<<4))&16\'hFFFF)');
    defineLines.push('`define imageH(index) ((`imgHeight>>((index)<<4))&16\'hFFFF)');

    defineLines.push('`define image(index,x,y) ' +
        `[((((\`itemStart>>(index)*24)&24'hFFFFFF)+((x)+(y)*\`imageW(index)))<<4)+:${imageBitdepth}]`);

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
    defineLines.push(`\`define itemStart ${itemOffset.length * 24}'h` + itemOffset.map(i => i.toString(16).padStart(6, '0')).join(''));
    imgWidth.reverse();
    defineLines.push(`\`define imgWidth ${imgWidth.length << 4}'h` + imgWidth.map(i => i.toString(16).padStart(4, '0')).join(''));
    imgHeight.reverse();
    defineLines.push(`\`define imgHeight ${imgHeight.length << 4}'h` + imgHeight.map(i => i.toString(16).padStart(4, '0')).join(''));

    defineLines.push(`\`define ${romDataOutputFile}${romIndex}ItemCount ${itemIndex}`);
    defineLines.push(`\`define ${romDataOutputFile}${romIndex}Length ${romDataSizeBit}`);
    fs.writeFileSync(resourcesDefineFile, defineLines.join('\n'));

    console.log(`Save ${romDataOutputFile}${romIndex}.hex: ${romDataSizeBit} bits`);
    fs.writeFileSync(`${romDataOutputFile}${romIndex}.hex`, romData.join(''));

}

function firstUpper(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}