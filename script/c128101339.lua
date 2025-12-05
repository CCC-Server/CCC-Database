local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon
	Xyz.AddProcedure(c,nil,4,2)
	c:EnableReviveLimit()

	---------------------------------------
	-- (1) Search "Stellaron Hunter" card
	---------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	---------------------------------------
	-- (2) Declare → reveal → 
	--     mismatch: destroy deck card
	--     match: control target monster
	---------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY + CATEGORY_CONTROL)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMING_END_PHASE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.cttg)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
end

---------------------------------------
-- (1) Search effect
---------------------------------------
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.thfilter(c)
	return c:IsSetCard(0xc47) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

---------------------------------------
-- (2) Declare → reveal → destroy or control
---------------------------------------

-- AnnounceType: 0 = Monster, 1 = Spell, 2 = Trap
local type_map={
	[0]=TYPE_MONSTER,
	[1]=TYPE_SPELL,
	[2]=TYPE_TRAP
}

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
	if chk==0 then
		return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil)
			and Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0
	end

	-- 필드 몬스터 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil)

	-- 카드 종류 선언
	local ann=Duel.AnnounceType(tp)
	e:SetLabel(ann)

	-- 파괴될 대상은 덱 위 카드
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_DECK)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget() -- 필드 몬스터
	if not tc or not tc:IsRelateToEffect(e) then return end

	-- Step 1: 덱 위 1장 확인
	local top=Duel.GetDecktopGroup(1-tp,1):GetFirst()
	if not top then return end

	Duel.ConfirmDecktop(1-tp,1)

	local declared=e:GetLabel()
	local match = top:IsType(type_map[declared])

	-------------------------------------
	-- Step 2: 선언 불일치 → 덱 카드 파괴
	-------------------------------------
	if not match then
		Duel.Destroy(top,REASON_EFFECT)
		return
	end

	-------------------------------------
	-- Step 3: 선언 일치 → 파괴 대신 컨트롤 획득
	-------------------------------------
	if tc:IsFaceup() and tc:IsRelateToEffect(e) then
		Duel.BreakEffect()
		Duel.GetControl(tc,tp,PHASE_END,1)
	end
end
