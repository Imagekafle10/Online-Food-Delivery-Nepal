import { useEffect, useMemo, useState, useRef, FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus, Pencil, Trash2, X, ImagePlus, FolderPlus, Bike, UserX } from 'lucide-react'
import { assetUrl } from '../api/client'
import RestaurantSearch from '../components/ui/RestaurantSearch'
import { selectBusinessWithMeta, Business } from '../features/business/businessSlice'
import { useAppDispatch, useAppSelector } from '../hooks/redux'
import {
  fetchMenu,
  createMenuItem,
  updateMenuItem,
  createMenuCategory,
  updateMenuCategory,
  removeMenuCategory,
  setItemAvailability,
  removeMenuItem,
  setSearch,
  clearMenuError,
  MenuItem,
  MenuItemInput,
  MIN_DISCOUNT_PERCENT,
  MAX_DISCOUNT_PERCENT,
} from '../features/menus/menusSlice'

const emptyForm: MenuItemInput = {
  name: '',
  description: '',
  price: 0,
  discount_percent: null,
  category_id: null,
  is_veg: true,
  prep_time_mins: 15,
}

// Effective price after applying discount_percent (5–90), matches backend/app logic.
function effectivePrice(item: { price: number; discount_percent?: number | null }): number {
  const price = Number(item.price)
  const pct = item.discount_percent
  return pct ? price * (1 - Number(pct) / 100) : price
}

export default function MenusPage() {
  const dispatch = useAppDispatch()
  const navigate = useNavigate()
  const selectedId = useAppSelector((s) => s.business.selectedId)
  const selectedMeta = useAppSelector((s) => s.business.selectedMeta)
  const role = useAppSelector((s) => s.auth.user?.role)
  const isAdmin = role === 'super_admin'
  const { categories, search, loading, saving, error, notice } = useAppSelector((s) => s.menus)
  const businessName = selectedMeta && selectedMeta.id === selectedId ? selectedMeta.name : null

  const [bizQuery, setBizQuery] = useState('')
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<MenuItem | null>(null)
  const [form, setForm] = useState<MenuItemInput>(emptyForm)
  const [formError, setFormError] = useState<string | null>(null)
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const [categoryModalOpen, setCategoryModalOpen] = useState(false)
  const [editingCategory, setEditingCategory] = useState<{ id: number; name: string } | null>(null)
  const [categoryName, setCategoryName] = useState('')
  const [categorySaving, setCategorySaving] = useState(false)
  const [categoryError, setCategoryError] = useState<string | null>(null)

  useEffect(() => {
    if (selectedId) dispatch(fetchMenu(selectedId))
  }, [selectedId, dispatch])

  const categoryOptions = useMemo(
    () => categories.filter((c) => c.id != null).map((c) => ({ id: c.id as number, name: c.name })),
    [categories]
  )

  const flatItems = useMemo(() => {
    const items = categories.flatMap((c) =>
      (c.items || []).map((item) => ({ ...item, categoryName: c.name }))
    )
    if (!search) return items
    const q = search.toLowerCase()
    return items.filter(
      (i) =>
        i.name.toLowerCase().includes(q) || String(i.categoryName).toLowerCase().includes(q)
    )
  }, [categories, search])

  const openCreate = () => {
    setEditing(null)
    setForm({ ...emptyForm, category_id: categoryOptions[0]?.id ?? null })
    setFormError(null)
    setImageFile(null)
    setImagePreview(null)
    dispatch(clearMenuError())
    setModalOpen(true)
  }

  const openEdit = (item: MenuItem & { categoryName?: string }) => {
    setEditing(item)
    setForm({
      name: item.name,
      description: item.description || '',
      price: Number(item.price),
      discount_percent: item.discount_percent != null ? Number(item.discount_percent) : null,
      category_id: item.category_id,
      is_veg: !!item.is_veg,
      prep_time_mins: item.prep_time_mins ?? 15,
    })
    setFormError(null)
    setImageFile(null)
    setImagePreview(assetUrl(item.image_url))
    dispatch(clearMenuError())
    setModalOpen(true)
  }

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] || null
    setImageFile(file)
    if (file) {
      setImagePreview(URL.createObjectURL(file))
    } else {
      setImagePreview(assetUrl(editing?.image_url))
    }
  }

  const clearImage = () => {
    setImageFile(null)
    setImagePreview(null)
    if (fileInputRef.current) fileInputRef.current.value = ''
  }

  const openCategoryModal = (cat?: { id: number; name: string }) => {
    setEditingCategory(cat ?? null)
    setCategoryName(cat?.name ?? '')
    setCategoryError(null)
    setCategoryModalOpen(true)
  }

  const handleSaveCategory = async (e: FormEvent) => {
    e.preventDefault()
    if (!selectedId || !categoryName.trim()) return
    setCategorySaving(true)
    setCategoryError(null)
    const name = categoryName.trim()
    const result = editingCategory
      ? await dispatch(
          updateMenuCategory({
            businessId: selectedId,
            categoryId: editingCategory.id,
            data: { name },
          })
        )
      : await dispatch(createMenuCategory({ businessId: selectedId, data: { name } }))
    setCategorySaving(false)
    const success = editingCategory
      ? updateMenuCategory.fulfilled.match(result)
      : createMenuCategory.fulfilled.match(result)
    if (success) {
      setCategoryModalOpen(false)
    } else {
      setCategoryError(
        (result.payload as string) ||
          (editingCategory ? 'Failed to update category' : 'Failed to create category')
      )
    }
  }

  const handleDeleteCategory = async (cat: { id: number; name: string }) => {
    if (!selectedId) return
    if (!confirm(`Delete category "${cat.name}"? Its items are kept and moved to "Other".`)) return
    const result = await dispatch(removeMenuCategory({ businessId: selectedId, categoryId: cat.id }))
    if (removeMenuCategory.fulfilled.match(result)) dispatch(fetchMenu(selectedId))
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    if (!selectedId || !form.name.trim() || form.price <= 0) return

    setFormError(null)
    if (
      form.discount_percent != null &&
      (form.discount_percent < MIN_DISCOUNT_PERCENT || form.discount_percent > MAX_DISCOUNT_PERCENT)
    ) {
      setFormError(`Discount must be between ${MIN_DISCOUNT_PERCENT}% and ${MAX_DISCOUNT_PERCENT}%`)
      return
    }

    const payload: MenuItemInput = {
      name: form.name.trim(),
      description: form.description || undefined,
      price: Number(form.price),
      discount_percent: form.discount_percent ? Number(form.discount_percent) : null,
      category_id: form.category_id || null,
      is_veg: form.is_veg,
      prep_time_mins: form.prep_time_mins || 15,
    }

    if (editing) {
      const result = await dispatch(
        updateMenuItem({
          businessId: selectedId,
          itemId: editing.id,
          data: payload,
          image: imageFile,
        })
      )
      if (updateMenuItem.fulfilled.match(result)) {
        setModalOpen(false)
        dispatch(fetchMenu(selectedId))
      }
    } else {
      const result = await dispatch(
        createMenuItem({ businessId: selectedId, data: payload, image: imageFile })
      )
      if (createMenuItem.fulfilled.match(result)) {
        setModalOpen(false)
        dispatch(fetchMenu(selectedId))
      }
    }
  }

  const switchRestaurant = (b: Business) => {
    dispatch(selectBusinessWithMeta({ id: b.id, name: b.name, type: b.type }))
    setBizQuery('')
  }

  // super_admin toolbar: switch restaurant + quick links to user monitoring and rider management
  const adminToolbar = isAdmin && (
    <div className="filters-bar">
      <RestaurantSearch
        value={bizQuery}
        onChange={setBizQuery}
        onPick={switchRestaurant}
        placeholder={businessName ? `Switch restaurant (now: ${businessName})` : 'Search restaurant…'}
      />
      <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
        <button className="btn btn-ghost btn-sm" onClick={() => navigate('/users')}>
          <UserX size={14} /> User suspension monitor
        </button>
        <button className="btn btn-ghost btn-sm" onClick={() => navigate('/riders')}>
          <Bike size={14} /> Rider management
        </button>
      </div>
    </div>
  )

  if (!selectedId) {
    return (
      <div>
        <div className="page-header">
          <h1>{isAdmin ? 'Menus' : 'My Menu'}</h1>
        </div>
        {adminToolbar}
        <div className="alert alert-info">
          {isAdmin
            ? 'No restaurant selected. Search above (or use the Restaurants page) to pick one.'
            : 'No business selected. Log in as a restaurant owner linked to a business.'}
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>{isAdmin ? `Menu${businessName ? ` — ${businessName}` : ''}` : 'My Menu'}</h1>
          <p>
            {isAdmin
              ? `Full control: add, edit, hide or delete any item · ${flatItems.length} items · business #${selectedId}`
              : `CRUD your products only · ${flatItems.length} items · business #${selectedId}`}
          </p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-ghost" onClick={() => openCategoryModal()}>
            <FolderPlus size={16} /> Add category
          </button>
          <button className="btn btn-primary" onClick={openCreate}>
            <Plus size={16} /> Add item
          </button>
        </div>
      </div>

      {adminToolbar}

      {error && <div className="alert alert-error">{error}</div>}
      {notice && <div className="alert alert-info">{notice}</div>}

      {categoryOptions.length > 0 && (
        <div className="category-chips">
          {categoryOptions.map((c) => (
            <span key={c.id} className="category-chip">
              {c.name}
              <button className="btn-icon" title="Rename category" onClick={() => openCategoryModal(c)}>
                <Pencil size={13} color="var(--gold)" />
              </button>
              <button className="btn-icon" title="Delete category" onClick={() => handleDeleteCategory(c)}>
                <Trash2 size={13} color="var(--danger)" />
              </button>
            </span>
          ))}
        </div>
      )}

      <div className="filters-bar">
        <input
          className="input"
          placeholder="Search items…"
          value={search}
          onChange={(e) => dispatch(setSearch(e.target.value))}
        />
        <button className="btn btn-ghost btn-sm" onClick={() => dispatch(fetchMenu(selectedId))}>
          Refresh
        </button>
      </div>

      <div className="card" style={{ padding: 0 }}>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Category</th>
                <th>Price</th>
                <th>Available</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={5} className="loading-row">
                    Loading…
                  </td>
                </tr>
              )}
              {!loading &&
                flatItems.map((item) => {
                  const available = !!item.is_available
                  return (
                    <tr key={item.id} className={available ? undefined : 'row-dim'}>
                      <td>
                        <strong>{item.name}</strong>
                        {item.description && (
                          <div className="muted" style={{ fontSize: 12, maxWidth: 260 }}>
                            {String(item.description).slice(0, 70)}
                          </div>
                        )}
                      </td>
                      <td>
                        <span className="badge badge-gold">{item.categoryName}</span>
                      </td>
                      <td>
                        <strong className="gold-text">
                          Rs. {effectivePrice(item).toFixed(2)}
                        </strong>
                        {!!item.discount_percent && (
                          <>
                            {' '}
                            <span
                              className="badge badge-success"
                              style={{ fontSize: 11, verticalAlign: 'middle' }}
                            >
                              {Number(item.discount_percent).toFixed(0)}% OFF
                            </span>
                          </>
                        )}
                      </td>
                      <td>
                        <select
                          className="input select"
                          style={{ width: 'auto', padding: '4px 28px 4px 8px', fontSize: 12 }}
                          value={available ? '1' : '0'}
                          onChange={(e) =>
                            dispatch(
                              setItemAvailability({
                                businessId: selectedId,
                                itemId: item.id,
                                is_available: e.target.value === '1',
                              })
                            )
                          }
                        >
                          <option value="1">Available</option>
                          <option value="0">Unavailable</option>
                        </select>
                      </td>
                      <td>
                        <div style={{ display: 'flex', gap: 4 }}>
                          <button className="btn-icon" title="Edit" onClick={() => openEdit(item)}>
                            <Pencil size={16} color="var(--gold)" />
                          </button>
                          <button
                            className="btn-icon"
                            title="Delete"
                            onClick={() => {
                              if (confirm(`Delete "${item.name}"?`)) {
                                dispatch(
                                  removeMenuItem({ businessId: selectedId, itemId: item.id })
                                )
                              }
                            }}
                          >
                            <Trash2 size={16} color="var(--danger)" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              {!loading && flatItems.length === 0 && (
                <tr>
                  <td colSpan={5} className="loading-row">
                    No items yet. Click “Add item”.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {modalOpen && (
        <div className="modal-overlay" onClick={() => setModalOpen(false)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>{editing ? 'Edit item' : 'Add item'}</h2>
              <button className="btn-icon" onClick={() => setModalOpen(false)}>
                <X size={18} />
              </button>
            </div>
            <form onSubmit={handleSubmit} className="modal-form">
              <div className="form-group">
                <label>Name *</label>
                <input
                  className="input"
                  required
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                />
              </div>
              <div className="form-group">
                <label>Image (optional)</label>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  {imagePreview ? (
                    <div style={{ position: 'relative' }}>
                      <img
                        src={imagePreview}
                        alt="Item preview"
                        style={{
                          width: 64,
                          height: 64,
                          objectFit: 'cover',
                          borderRadius: 8,
                          border: '1px solid var(--border, #333)',
                        }}
                      />
                      <button
                        type="button"
                        className="btn-icon"
                        title="Remove image"
                        onClick={clearImage}
                        style={{
                          position: 'absolute',
                          top: -8,
                          right: -8,
                          background: 'var(--danger)',
                          borderRadius: '50%',
                        }}
                      >
                        <X size={12} color="#fff" />
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      className="btn btn-ghost btn-sm"
                      onClick={() => fileInputRef.current?.click()}
                    >
                      <ImagePlus size={16} /> Upload image
                    </button>
                  )}
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={handleImageChange}
                  />
                  {imagePreview && (
                    <button
                      type="button"
                      className="btn btn-ghost btn-sm"
                      onClick={() => fileInputRef.current?.click()}
                    >
                      Change
                    </button>
                  )}
                </div>
              </div>
              <div className="form-group">
                <label>Description</label>
                <textarea
                  className="input"
                  rows={2}
                  value={form.description || ''}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                />
              </div>
              <div className="form-row">
                <div className="form-group">
                  <label>Price (Rs) *</label>
                  <input
                    className="input"
                    type="number"
                    min={0}
                    step={0.01}
                    required
                    value={form.price || ''}
                    onChange={(e) => setForm({ ...form, price: Number(e.target.value) })}
                  />
                </div>
                <div className="form-group">
                  <label>Discount % (5–90)</label>
                  <input
                    className="input"
                    type="number"
                    min={MIN_DISCOUNT_PERCENT}
                    max={MAX_DISCOUNT_PERCENT}
                    step={1}
                    placeholder="e.g. 15"
                    value={form.discount_percent ?? ''}
                    onChange={(e) =>
                      setForm({
                        ...form,
                        discount_percent: e.target.value ? Number(e.target.value) : null,
                      })
                    }
                  />
                </div>
              </div>
              {form.price > 0 && !!form.discount_percent && (
                <p className="muted" style={{ fontSize: 12.5, marginTop: -8 }}>
                  Customer pays Rs. {effectivePrice({ price: form.price, discount_percent: form.discount_percent }).toFixed(2)} (was Rs. {Number(form.price).toFixed(2)})
                </p>
              )}
              <div className="form-row">
                <div className="form-group">
                  <label>Category</label>
                  <select
                    className="input select"
                    value={form.category_id ?? ''}
                    onChange={(e) =>
                      setForm({
                        ...form,
                        category_id: e.target.value ? Number(e.target.value) : null,
                      })
                    }
                  >
                    <option value="">Other</option>
                    {categoryOptions.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label>Prep time (mins)</label>
                  <input
                    className="input"
                    type="number"
                    min={1}
                    value={form.prep_time_mins ?? 15}
                    onChange={(e) => setForm({ ...form, prep_time_mins: Number(e.target.value) })}
                  />
                </div>
              </div>
              <label className="check-row">
                <input
                  type="checkbox"
                  checked={!!form.is_veg}
                  onChange={(e) => setForm({ ...form, is_veg: e.target.checked })}
                />
                Vegetarian
              </label>
              {(formError || error) && (
                <p style={{ color: 'var(--danger)', fontSize: 13 }}>{formError || error}</p>
              )}
              <div className="modal-actions">
                <button type="button" className="btn btn-ghost" onClick={() => setModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving…' : editing ? 'Update' : 'Create'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {categoryModalOpen && (
        <div className="modal-overlay" onClick={() => setCategoryModalOpen(false)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>{editingCategory ? 'Rename category' : 'Add category'}</h2>
              <button className="btn-icon" onClick={() => setCategoryModalOpen(false)}>
                <X size={18} />
              </button>
            </div>
            <form onSubmit={handleSaveCategory} className="modal-form">
              <div className="form-group">
                <label>Category name *</label>
                <input
                  className="input"
                  required
                  autoFocus
                  value={categoryName}
                  onChange={(e) => setCategoryName(e.target.value)}
                  placeholder="e.g. Beverages"
                />
              </div>
              {categoryError && <p style={{ color: 'var(--danger)', fontSize: 13 }}>{categoryError}</p>}
              <div className="modal-actions">
                <button
                  type="button"
                  className="btn btn-ghost"
                  onClick={() => setCategoryModalOpen(false)}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary" disabled={categorySaving}>
                  {categorySaving ? 'Saving…' : editingCategory ? 'Save' : 'Create'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
