#pragma once

#include <thrust/iterator/iterator_adaptor.h>
#include <thrust/iterator/counting_iterator.h>

namespace detail_
{


template<typename SegmentIterator> class distributed_iterator;


template<typename SegmentIterator>
  struct distributed_iterator_base
{
  typedef typename thrust::iterator_value<SegmentIterator>::type      element_iterator;

  typedef distributed_iterator<SegmentIterator>                       derived_iterator;
  typedef thrust::counting_iterator<unsigned int>                     base_iterator;
  typedef typename thrust::iterator_pointer<element_iterator>::type   pointer;
  typedef typename thrust::iterator_value<element_iterator>::type     value_type;
  typedef typename thrust::iterator_system<element_iterator>::type    system;
  typedef typename thrust::random_access_traversal_tag                traversal;
  typedef typename thrust::iterator_reference<element_iterator>::type reference;

  typedef thrust::experimental::iterator_adaptor<
    derived_iterator,
    base_iterator,
    pointer,
    value_type,
    system,
    traversal,
    reference
  > type;
};


template<typename SegmentIterator>
  class distributed_iterator
    : public distributed_iterator_base<SegmentIterator>::type
{
  private:
    typedef SegmentIterator segment_iterator;
    typedef typename thrust::iterator_value<SegmentIterator>::type segment_type;
    typedef typename distributed_iterator_base<SegmentIterator>::type super_t;

    friend class thrust::experimental::iterator_core_access;

  public:
    typedef typename super_t::difference_type difference_type;

    __host__ __device__
    distributed_iterator(){}

    __host__ __device__
    distributed_iterator(const distributed_iterator &other)
      : super_t(other.base()),
        m_segments(other.m_segments),
        m_segment_size(other.m_segment_size)
    {}

    template<typename OtherSegmentIterator, typename Size>
    __host__ __device__
    distributed_iterator(OtherSegmentIterator segments_first, 
                         Size segment_size,
                         difference_type initial_index = 0)
      : super_t(thrust::counting_iterator<unsigned int>(initial_index)),
        m_segments(segments_first),
        m_segment_size(segment_size)
    {}

  protected:
    __host__ __device__
    typename super_t::reference dereference() const
    {
      const difference_type i = *super_t::base_reference();

      // which segment are we in?
      difference_type segment_idx = i / m_segment_size;

      // which element within the segment are we?
      difference_type remainder = i - (m_segment_size * segment_idx);

      // dereference twice

      // first, get the segment
      // assign it to a temporary to handle the case where m_segments[segment_idx]
      // returns a wrapped reference
      const segment_type &segment = m_segments[segment_idx];

      // index into the segment
      return segment[remainder];
    }

  private:
    segment_iterator m_segments;
    difference_type m_segment_size;
};


} // end detail

