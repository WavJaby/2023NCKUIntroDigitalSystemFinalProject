const fs = require('fs');
const Sharp = require('sharp');
const Path = require('path');
const RgbQuant = require('rgbquant');
const Fontkit = require('fontkit');
const { joinImages: JoinImages } = require('join-images');

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
    createImageFromPath,
    extractFont,
};

if (require.main === module) (async function () {
    const imagePath = process.argv[2];
    const toWidth = parseInt(process.argv[3]);
    // console.log('open: ' + imagePath);

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

    // const sharpImg = Sharp(imagePath);
    // const { imageWidth, imageHeight } = await createImage(sharpImg, -1, toWidth, '.', true, false, true, true);
    // console.log(imageWidth + 'x' + imageHeight);
})();

async function extractFont(fontPath, cacheFolder, toWordHeight, wordRightCut, processScale) {
    if (wordRightCut == null)
        wordRightCut = -1;
    if (processScale == null)
        processScale = 6;

    const font = Fontkit.openSync(fontPath);
    console.log(`Use font: ${font.fullName}`);
    console.log(`  family: ${font.familyName}`);
    const fontName = font.familyName;
    const bound = { minX: null, maxX: null, maxY: null, minY: null, width: 0, height: 0 };
    const characterList = [];
    for (let i = 33; i < 127; i++) {
        const char = String.fromCharCode(i);
        const g = font.layout(char).glyphs[0];
        if (g.name === '.notdef')
            continue;

        const textBound = g.cbox;
        if (bound.minX == null || textBound.minX < bound.minX) bound.minX = textBound.minX;
        if (bound.maxX == null || textBound.maxX > bound.maxX) bound.maxX = textBound.maxX;
        if (bound.minY == null || textBound.minY < bound.minY) bound.minY = textBound.minY;
        if (bound.maxY == null || textBound.maxY > bound.maxY) bound.maxY = textBound.maxY;
        characterList.push({ char, glyph: g });
    }
    bound.width = bound.maxX - bound.minX;
    bound.height = bound.maxY - bound.minY;
    let scale = toWordHeight / bound.height;
    console.log(`font scale: ${bound.width}x${bound.height}, gcd: ${gcd(bound.width, bound.height)}`);
    const wordWidth = bound.width * scale + 0.5 | 0;
    const wordHight = toWordHeight + 0.5 | 0;
    console.log(`process scale: ${scale} ${wordWidth}x${wordHight}`);
    // console.log(bound);

    // Extract character from font file
    const textImages = [];
    let imagesProc = [];
    console.time('Font to image');
    let textOffXRight = 0;
    for (const { char, glyph } of characterList) {
        const textBound = glyph.cbox;
        const h = textBound.height * scale + 0.5 | 0;
        const offY = (bound.height - (textBound.minY - bound.minY + textBound.height)) * scale + 0.5 | 0;
        const offX = textBound.minX * scale + 0.5 | 0;
        const textImg = Sharp({
            text: {
                text: '<span color="#FFF">' + textEscape(char) + '</span>',
                font: fontName,
                fontfile: fontPath,
                rgba: true,
                spacing: 0,
                width: wordWidth * processScale,
                height: h * processScale
            }
        }).resize({ height: h, kernel: 'nearest' });
        const outPath = Path.join(cacheFolder, `${textEscape(char)}.png`);
        imagesProc.push(textImg.toFile(outPath));
        const charWidth = (glyph.advanceWidth * scale + 0.5 | 0) + wordRightCut;
        textImages.push({ textBound, src: outPath, localOffsetLeft: offX, width: charWidth, offsetX: offX + textOffXRight, offsetY: offY });
        textOffXRight = ((glyph.advanceWidth - textBound.width - textBound.minX) * scale + 0.5 | 0) + wordRightCut;
    }
    imagesProc = await Promise.all(imagesProc);
    console.timeEnd('Font to image');
    let textOffX = 0;
    const characterOffsets = [];
    for (let i = 0; i < imagesProc.length; i++) {
        const { offsetX, localOffsetLeft, width } = textImages[i];
        const offsetLeft = offsetX + textOffX - localOffsetLeft;
        characterOffsets.push({ offset: offsetLeft, char: characterList[i].char, width });
        const image = imagesProc[i];
        textOffX += offsetX + image.width;
    }
    // console.log(textOffset);

    // Join all text
    const allTextImg = await JoinImages(textImages, { direction: 'horizontal', offset: 0 });
    await allTextImg.toFile('cache-fontResult.png');
    const image = await allTextImg.raw().greyscale().toBuffer({ resolveWithObject: true });

    const data = image.data, imageInfo = image.info;
    const imageWidth = imageInfo.width, imageHeight = imageInfo.height;

    // console.log('create hex file');
    const hexResult = [];
    let row = new Array(imageWidth);
    for (let i = 0, j = 0; i < data.length; i++) {
        row[j] = data[i] > 127 ? '1' : '0';

        if (++j === imageWidth) {
            row.reverse();
            hexResult.push(row.join(''));
            row = new Array(imageWidth);
            j = 0;
        }
    }

    return {
        hexResult: hexResult, imageWidth, imageHeight,
        characterOffsets, charMaxWidth: wordWidth,
    };
    // fs.writeFileSync('cache-fontResult.hex', hexResult.join('\n'));

    // const text = Sharp({
    //     text: {
    //         text: '<span color="#FFF">' +
    //             inputText.map(i => textEscape(i.char)).join('') + '</span>',
    //         font: fontName,
    //         fontfile: fontPath,
    //         rgba: true,
    //         spacing: 0,
    //         width: wordWidth * inputText.length * processScale * 2,
    //         height: wordHight * processScale
    //     }
    // }).resize({ height: wordHight, kernel: 'nearest' });
    // await text.toFile('cache-fontResult2.png');
    // console.log(await text.metadata());
}

function textEscape(char) {
    const code = char.charCodeAt(0);
    if (code > 31 && code < 127)
        return '&#' + code.toString() + ';';
    return char;
}

function gcd(a, b) {
    if (!b)
        return a;
    return gcd(b, a % b);
}

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
    if (toWidth != null && addPadding) {
        const padding = inImageInfo.width / toWidth / 2 | 0;
        console.log(`Extra padding: ${padding}`)
        sharpImg.extend({
            top: padding, left: padding, bottom: padding, right: padding, background: { r: 0, g: 0, b: 0, alpha: 0 }
        });
    }
    let image = await sharpImg.raw().toBuffer({ resolveWithObject: true });
    if (toWidth != null)
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
    let row = new Array(imageWidth);
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
            row = new Array(imageWidth);
            j = 0;
        }

        debugResult[i] = b0 << 4;
        debugResult[i + 1] = b1 << 4;
        debugResult[i + 2] = b2 << 4;
        debugResult[i + 3] = b3 << 4;
    }
    const outputPath = Path.join(outDir, outName + '.hex');
    if (reverce) hexResult.reverse();
    if (saveHexFile)
        fs.writeFileSync(outputPath, hexResult.join('\n'));

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

    return { imageWidth, imageHeight, outputPath, imageHexData: hexResult };
}