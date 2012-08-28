#include "detail/distributed_iterator.hpp"
#include <vector>
#include <algorithm>
#include <iterator>
#include <cassert>

template<typename T>
std::vector<T> flatten(const std::vector<std::vector<T> > &ranges)
{
  std::vector<T> result;
  for(typename std::vector<std::vector<T> >::const_iterator rng = ranges.begin();
      rng != ranges.end();
      ++rng)
  {
    std::copy(rng->begin(), rng->end(), std::back_inserter(result));
  }

  return result;
}

int main()
{
  std::size_t num_segments = 4;
  std::vector<std::vector<int> > data(num_segments);

  std::size_t segment_size = 5;

  for(int i = 0; i < data.size(); ++i)
  {
    data[i].resize(segment_size, i);
  }

  std::vector<std::vector<int>::pointer> segments(4);

  for(int i = 0; i < data.size(); ++i)
  {
    segments[i] = data[i].data();
  }

  detail::distributed_iterator<
    std::vector<
      std::vector<int>::pointer
    >::iterator
  > distributed_first(segments.begin(), segment_size, 0);

  detail::distributed_iterator<
    std::vector<
      std::vector<int>::pointer
    >::iterator
  > distributed_last = distributed_first + num_segments * segment_size;

  assert(std::equal(distributed_first, distributed_last, flatten(data).begin()));

  return 0;
}

