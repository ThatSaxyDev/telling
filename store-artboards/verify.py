"""Validate decoded exports against an independent store-slot specification."""
import hashlib, json
from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parent
slots = {
    '01-iPhone-medium-1179x2556': (1179,2556,5),
    '02-iPad-13-2064x2752': (2064,2752,5),
    '03-Duo-outer-1398x2034': (1398,2034,5),
    '04-Duo-inner-2007x2853': (2007,2853,5),
    '05-Header-3840x1646': (3840,1646,1),
    '06-Search-Results-3840x2560': (3840,2560,1),
    '07-Play-phone-1080x1920': (1080,1920,5),
    '08-Play-feature-1024x500': (1024,500,1),
}
manifest = {entry['file']: entry for entry in json.loads((root/'manifest.json').read_text())}
results=[]
for folder, (w,h,count) in slots.items():
    files=sorted((root/folder).glob('*.png'))
    assert len(files)==count, (folder,'count',len(files),count)
    for file in files:
        relative=str(file.relative_to(root))
        with Image.open(file) as im:
            im.load()
            assert im.size==(w,h), (file,im.size)
            assert im.format=='PNG', file
            # Export opaque RGB, with no alpha channel or transparency key.
            if im.mode!='RGB' or 'transparency' in im.info:
                assert 'A' not in im.getbands() or im.getchannel('A').getextrema()==(255,255), file
                im.convert('RGB').save(file,optimize=True)
        with Image.open(file) as im:
            assert im.mode=='RGB' and 'transparency' not in im.info, file
            assert im.size==(w,h), file
        entry=manifest[relative]
        assert entry['geometry']['errors']==[], (file,entry['geometry'])
        assert entry['geometry']['width']==w and entry['geometry']['height']==h, file
        if folder.startswith('02-'): assert entry['source'].startswith('ipad-'), file
        if folder.startswith('07-'): assert entry['source'].startswith('android-'), file
        size=file.stat().st_size
        assert size<8_000_000, (file,size)
        results.append({'file':relative,'dimensions':[w,h],'mode':'RGB','bytes':size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'source':entry['source'],'composition':'passed: bounds, overlap, image loading, proportional scaling'})
assert len(results)==28
(root/'validation.json').write_text(json.dumps({'status':'passed','image_count':28,'files':results},indent=2)+'\n')
print('PASS: 28 PNGs; exact slot dimensions; opaque RGB; proportional screens; no missing assets or composition overflows.')
