/// How a chart should combine the values within a single time bucket.
typedef BucketCombiner = double Function(List<double> bucketValues);

double combineByAverage(List<double> bucketValues) =>
    bucketValues.reduce((a, b) => a + b) / bucketValues.length;

double combineBySum(List<double> bucketValues) =>
    bucketValues.reduce((a, b) => a + b);
