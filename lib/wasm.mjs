import * as emnapi from '@emnapi/runtime';
import bindings from '../build/Release/blob.mjs';

const result = bindings()
    .then((m) => m.emnapiInit({ context: emnapi.getDefaultContext() }));

export default result;
