import * as emnapi from '@emnapi/runtime';
import bindings from '../build/Release/blob.js';

const result = bindings()
    .then((m) => m.emnapiInit({ context: emnapi.getDefaultContext() }));

export default result;
