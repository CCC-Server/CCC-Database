--Over Limit - Clash Out
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------
	-- ① 이 카드명은 필드/묘지에서 "Limiter Removal" 취급
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_SZONE+LOCATION_GRAVE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetValue(23171610) -- "Limiter Removal"
	c:RegisterEffect(e1)

	--------------------------------
	-- ② 마함 발동에 체인 → 발동 무효 + 내 "Over Limit" 몬스터 1장 파괴
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_CHAINING)
	-- "You can only use 1 of the following effects ... per turn, and only once that turn."
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	--------------------------------
	-- ③ "Limiter Removal" 발동 시, 묘지에서 세트
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	-- ②/③ 공용 카운트 제한
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.setcon)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

-- "Limiter Removal"
s.listed_names={23171610}
-- "Over Limit" 카드군
s.listed_series={0xc48}

--------------------------------
-- ② 관련
--------------------------------
-- 상대가 마함 카드/효과 발동 시
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp
		and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
		and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

-- 내 "Over Limit" 몬스터 (통상 앞면 기준)
function s.olfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc48) and c:IsType(TYPE_MONSTER)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	-- 발동 무효
	if Duel.NegateActivation(ev)==0 then return end
	-- 그 후, 내가 조종하는 "Over Limit" 몬스터 1장 파괴
	if not Duel.IsExistingMatchingCard(s.olfilter,tp,LOCATION_MZONE,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.olfilter,tp,LOCATION_MZONE,0,1,1,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--------------------------------
-- ③ 관련: "Limiter Removal" 발동 시 묘지에서 세트
--------------------------------
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and rc:IsCode(23171610)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SSet(tp,c)
	end
end
