#include "detail/distributed_iterator.hpp"
#include <vector>
#include <thrust/device_vector.h>
#include <thrust/copy.h>
#include <thrust/equal.h>
#include <cassert>

template<typename T>
thrust::device_vector<T> flatten(const std::vector<thrust::device_vector<T> > &ranges)
{
  thrust::device_vector<T> result;
  for(typename std::vector<thrust::device_vector<T> >::const_iterator rng = ranges.begin();
      rng != ranges.end();
      ++rng)
  {
    result.insert(result.end(), rng->begin(), rng->end());
  }

  return result;
}

int main()
{
  std::size_t num_segments = 4;
  std::vector<thrust::device_vector<int> > data(num_segments);

  std::size_t segment_size = 5;

  for(int i = 0; i < data.size(); ++i)
  {
    data[i].resize(segment_size, i);
  }

  thrust::device_vector<thrust::device_vector<int>::pointer> segments(4);

  for(int i = 0; i < data.size(); ++i)
  {
    segments[i] = data[i].data();
  }

  detail_::distributed_iterator<
    thrust::device_vector<
      thrust::device_vector<int>::pointer
    >::iterator
  > distributed_first(segments.begin(), segment_size, 0);

  detail_::distributed_iterator<
    thrust::device_vector<
      thrust::device_vector<int>::pointer
    >::iterator
  > distributed_last = distributed_first + num_segments * segment_size;

  assert(thrust::equal(distributed_first, distributed_last, flatten(data).begin()));

  return 0;
}

