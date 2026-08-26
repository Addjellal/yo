function r = ycbcr2rgb(image)
%YCBCR2RGB Luminance et chrominances vers RVB.
    estEntier = isa(image, 'uint8');
    x = im2double(image);
    Y = x(:, :, 1) * 255; Cb = x(:, :, 2) * 255; Cr = x(:, :, 3) * 255;
    R = 255 / 219 * (Y - 16) + 255 / 224 * 1.402 * (Cr - 128);
    G = 255 / 219 * (Y - 16) - 255 / 224 * 1.772 * 0.114 / 0.587 * (Cb - 128) ...
        - 255 / 224 * 1.402 * 0.299 / 0.587 * (Cr - 128);
    B = 255 / 219 * (Y - 16) + 255 / 224 * 1.772 * (Cb - 128);
    r = cat(3, R, G, B) / 255;
    r = min(max(r, 0), 1);
    if estEntier, r = im2uint8(r); end
end
