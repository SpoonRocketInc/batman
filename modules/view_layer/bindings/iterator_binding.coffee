AbstractCollectionBinding = require './abstract_collection_binding'
IteratorView = require '../iterator_view'

BindingDefinitionOnlyObserve = require '../dom/binding_definition_only_observe'

module.exports = class IteratorBinding extends AbstractCollectionBinding
  onlyObserve: BindingDefinitionOnlyObserve.Data
  backWithView: IteratorView
  skipChildren: true
  bindImmediately: false

  constructor: (definition) ->
    @iteratorName = definition.attr
    @prototypeNode = definition.node
    @prototypeNode.removeAttribute("data-foreach-#{@iteratorName}")

    definition.viewOptions = {@prototypeNode, @iteratorName, iteratorPath: definition.keyPath}
    definition.node = null

    super

    @backingView.set('attributeName', @attributeName)
    @view.prevent('ready')
    @_handle = Batman.setImmediate =>
      if @backingView.isDead
        Batman.developer.warn "IteratorBinding (data-foreach-#{@iteratorName}='#{@keyPath}') trying to insert dead backing view into DOM (#{@view.constructor.name})"
        return

      parentNode = @prototypeNode.parentNode
      parentNode.insertBefore(@backingView.get('node'), @prototypeNode)
      parentNode.removeChild(@prototypeNode)

      @bind()
      @view.allowAndFire('ready')

  handleArrayChanged: (newItems) =>
    unless @backingView.isDead
      @backingView.destroySubviews()
      @handleItemsAdded(newItems) if newItems?.length

  handleItemsAdded: (addedItems, addedIndexes) =>
    unless @backingView.isDead
      @backingView.addItems(addedItems, addedIndexes)

  handleItemsRemoved: (removedItems, removedIndexes) =>
    return if @backingView.isDead

    if @collection.length
      @backingView.removeItems(removedItems, removedIndexes)
    else
      @backingView.destroySubviews()

  handleItemMoved: (item, newIndex, oldIndex) =>
    unless @backingView.isDead
      @backingView.moveItem(oldIndex, newIndex)

  die: ->
    Batman.clearImmediate(@_handle) if @_handle
    @prototypeNode = null
    super
