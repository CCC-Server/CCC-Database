--검투수 트라디토르
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon (Quick)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--Search (Mandatory)
	--②: 엑스트라 덱에서 몬스터가 특수 소환되었을 경우에 발동한다. 
	--이 카드의 원래의 주인은, 덱에서 "글래디얼(0x4d)"이나 "검투(0x19)" 마법 / 함정 카드 1장을 패에 넣는다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F) -- 강제 효과
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	
	--Tag Out
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.tagcon)
	e3:SetTarget(s.tagtg)
	e3:SetOperation(s.tagop)
	c:RegisterEffect(e3)
end

-- E1: Special Summon Logic
function s.cfilter(c)
	-- 0x19: Gladiator Beast
	return c:IsFaceup() and c:IsSetCard(0x19)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local c=e:GetHandler()
		return c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,tp)
			or c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,tp)
	local b2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp)
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif b1 then
		op=0
	elseif b2 then
		op=1
	else
		return
	end
	local p = (op==0) and tp or 1-tp
	Duel.SpecialSummon(c,0,tp,p,false,false,POS_FACEUP)
end

-- E2: Search Logic
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	-- Check if any monster was summoned from Extra Deck
	return eg:IsExists(Card.IsSummonLocation,1,nil,LOCATION_EXTRA)
end

function s.thfilter(c)
	-- 0x4d: Gradius/Gladial, 0x19: Gladiator Beast
	return (c:IsSetCard(0x4d) or c:IsSetCard(0x19)) 
		and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local owner = e:GetHandler():GetOwner()
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,owner,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- Identify the ORIGINAL OWNER of this card
	local owner = e:GetHandler():GetOwner()
	
	-- Effect resolves for the OWNER
	Duel.Hint(HINT_SELECTMSG,owner,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(owner,s.thfilter,owner,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-owner,g)
	end
end

-- E3: Tag Out Logic
function s.tagcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetBattledGroupCount()>0
end
function s.tagfilter(c,e,tp)
	-- 0x19: Gladiator Beast
	return c:IsSetCard(0x19) and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,113,tp,false,false)
end
function s.tagtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tagfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.tagop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() and Duel.SendtoDeck(c,nil,2,REASON_EFFECT)~=0 and c:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.tagfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,113,tp,tp,false,false,POS_FACEUP)
		end
	end
end