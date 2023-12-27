const fs = require('fs');
const { createImage, createImageFromPath } = require('./imageProcess.js');

const outputFile = 'rom';
const defineFile = '../src/resources_define.v';
const imageBitdepth = 16;
const resources = [
    ['sphere.png', 32, true],
    ['DVD_logo.png', 64, false],
    ['brick.png', 64, false],
    ['shoto.png', 64, false],
];
const defineLines = [];

(async function () {
    let romIndex = 0;
    let romLen = 0;
    let itemIndex = 0;
    let itemOff = [0];
    let rom = [];

    defineLines.push(`\`define imageBitdepth ${imageBitdepth}`);
    defineLines.push('`define imageW(index) ((`imgWidth>>((index)<<4))&16\'hFFFF)');
    defineLines.push('`define imageH(index) ((`imgHeight>>((index)<<4))&16\'hFFFF)');

    defineLines.push('`define image(index,x,y) ' +
        `[((((\`itemStart>>(index)*24)&24'hFFFFFF)+((x)+(y)*\`imageW(index)))<<4)+:${imageBitdepth}]`);

    let imgWidth = [], imgHeight = [];
    for (const resource of resources) {
        const imageData = await createImageFromPath(...resource, true);
        const hexData = imageData.imageHexData;

        romLen += hexData.reduce((a, b) => a + b.length * 4, 0);
        const itemData = hexData.join('');
        rom.unshift(itemData);
        imgWidth.push(imageData.imageWidth);
        imgHeight.push(imageData.imageHeight);
        defineLines.push(`// item${itemIndex}(${resource[0]}): ${imageData.imageWidth}x${imageData.imageHeight}`);

        if (itemIndex + 1 < resources.length)
            itemOff.push(itemOff[itemOff.length - 1] + (itemData.length >> 2));

        itemIndex++;
    }
    itemOff.reverse();
    defineLines.push(`\`define itemStart ${itemOff.length * 24}'h` + itemOff.map(i => i.toString(16).padStart(6, '0')).join(''));
    imgWidth.reverse();
    defineLines.push(`\`define imgWidth ${imgWidth.length << 4}'h` + imgWidth.map(i => i.toString(16).padStart(4, '0')).join(''));
    imgHeight.reverse();
    defineLines.push(`\`define imgHeight ${imgHeight.length << 4}'h` + imgHeight.map(i => i.toString(16).padStart(4, '0')).join(''));

    defineLines.push(`\`define ${outputFile}${romIndex}ItemCount ${itemIndex}`);
    defineLines.push(`\`define ${outputFile}${romIndex}Length ${romLen}`);
    fs.writeFileSync(defineFile, defineLines.join('\n'));

    console.log(`Save rom: ${romIndex}, ${romLen} bits`);
    fs.writeFileSync(`${outputFile}${romIndex}.hex`, rom.join(''));
})();