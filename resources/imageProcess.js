const fs = require('fs');
const Sharp = require('sharp');
const Path = require('path');
const RgbQuant = require('rgbquant');

// Create palette
const palette = new Array(4096);
for (let r = 0, i = 0; r < 16; r++) {
    for (let g = 0; g < 16; g++) {
        for (let b = 0; b < 16; b++) {
            palette[i] = new Uint8Array(3);
            palette[i][0] = r * 16;
            palette[i][1] = g * 16;
            palette[i][2] = b * 16;
            i++;
        }
    }
}
const options = {
    colors: 4096,
    method: 2,
    boxSize: [64, 64],
    boxPxls: 2,
    initColors: 4096,
    minHueCols: 0,
    dithKern: 'FloydSteinberg',
    dithDelta: 0,
    dithSerp: false,
    palette: palette,
    reIndex: false,
    useCache: true,
    cacheFreq: 10,
    colorDist: "euclidean",
};

module.exports = {
    createImage,
    createImageFromPath
};

if (require.main === module) (async function () {
    const imagePath = process.argv[2];
    const toWidth = parseInt(process.argv[3]);
    console.log('open: ' + imagePath);

    // const gifImage = Sharp(imagePath, { animated: true })
    // const gifInfo = await gifImage.metadata();
    // // console.log(gifInfo);

    // const gap = Math.max(1, gifInfo.pages / 8);
    // let index = 0;
    // for (let page = 0; page < gifInfo.pages; page += gap) {
    //     const pageInt = page | 0;
    //     console.log(`page: ${pageInt}`);
    //     const offset = gifInfo.pageHeight * pageInt;
    //     const frame = gifImage.clone()
    //         .extract({ left: 0, top: offset, width: gifInfo.width, height: gifInfo.pageHeight });
    //     // console.log(frame);
    //     await createImage(frame, index++, toWidth, 'chipi_', false, false, true, false);
    // }
    // console.log(`totalPages: ${index}`);

    const sharpImg = Sharp(imagePath);
    const { imageWidth, imageHeight } = await createImage(sharpImg, -1, toWidth, '.', true, false, true, true);
    console.log(imageWidth + 'x' + imageHeight);
})();

async function createImageFromPath(imagePath, toWidth, addPadding, reverce, saveHexFile) {
    const sharpImg = Sharp(imagePath);
    return createImage(sharpImg, -1, toWidth, '.', addPadding, reverce, saveHexFile, false);
}

async function createImage(sharpImg, page, toWidth, outDir, addPadding, reverce, saveHexFile, debug) {
    const inImageInfo = await sharpImg.metadata();
    let outName = Path.parse(sharpImg.options.input.file).name;
    if (page !== -1)
        outName += '_' + page;
    fs.mkdirSync(outDir, { recursive: true });

    // console.log('resize image');
    // Add extra padding if need 
    if (addPadding) {
        const padding = inImageInfo.width / toWidth / 2 | 0;
        console.log(`Extra padding: ${padding}`)
        sharpImg.extend({
            top: padding, left: padding, bottom: padding, right: padding, background: { r: 0, g: 0, b: 0, alpha: 0 }
        });
    }
    let image = await sharpImg.raw().toBuffer({ resolveWithObject: true });
    image = await Sharp(image.data, { raw: image.info })
        .resize(toWidth, null, { kernel: 'mitchell' })
        .raw().toBuffer({ resolveWithObject: true });

    const data = image.data, imageInfo = image.info;
    const imageWidth = imageInfo.width, imageHeight = imageInfo.height;

    // console.log('reduce image');
    const quant = new RgbQuant(options);
    quant.sample(data, imageWidth);
    const out = quant.reduce(new Uint8Array(data));

    // console.log('create hex file');
    const debugResult = new Uint8Array(data.length);
    const hexResult = [];
    let row = [];
    for (let i = 0, j = 0; i < out.length; i += 4) {
        let b0 = out[i], b1 = out[i + 1], b2 = out[i + 2], b3 = data[i + 3];
        b0 >>= 4;
        b1 >>= 4;
        b2 >>= 4;
        b3 >>= 4;

        if (b3 === 0)
            row[j] = '0000';
        else
            row[j] =
                (b0).toString(16) +
                (b1).toString(16) +
                (b2).toString(16) +
                (b3).toString(16);

        if (++j === imageWidth) {
            if (reverce) row.reverse();
            hexResult.push(row.join(''));
            row = [];
            j = 0;
        }

        debugResult[i] = b0 << 4;
        debugResult[i + 1] = b1 << 4;
        debugResult[i + 2] = b2 << 4;
        debugResult[i + 3] = b3 << 4;
    }
    const outputPath = Path.join(outDir, outName + '.hex');
    if (reverce) hexResult.reverse();
    const imageHexData = hexResult;
    if (saveHexFile)
        fs.writeFileSync(outputPath, imageHexData.join('\n'));

    if (debug) {
        console.log('create out image');
        Sharp(debugResult, {
            raw: {
                width: imageWidth,
                height: imageHeight,
                channels: 4
            }
        })
            .toFile(Path.join(outDir, outName + '_out.png'));
    }

    return { imageWidth, imageHeight, outputPath, imageHexData };
}