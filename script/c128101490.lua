--검투수 헤파이트라스 (수정본)
local s,id=GetID()
local SET_GLADIATOR_BEAST=0x19 -- 검투수 카드군 코드

s.listed_series={SET_GLADIATOR_BEAST}

function s.initial_effect(c)
	-- 융합 소재: "검투수" 몬스터 x 2
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.matfilter,2,2)
	
	-- 콘택트 융합 (자신 필드의 상기 카드를 덱으로 되돌렸을 경우에만 엑스트라 덱에서 특수 소환)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.contactcon)
	e0:SetTarget(s.contacttg)
	e0:SetOperation(s.contactop)
	c:RegisterEffect(e0)

	-- (1) 특수 소환 성공 시: 덱 덤핑 후 "검투수" 마함 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)

	-- (2) 배틀 페이즈 종료 시 태그 아웃
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1}) -- (2) 효과 하드 OPT 공유
	e2:SetCondition(s.tagcon_bp)
	e2:SetCost(s.tagcost)
	e2:SetTarget(s.tagtg)
	e2:SetOperation(s.tagop)
	c:RegisterEffect(e2)

	-- (2) 상대 효과 발동 시 태그 아웃 (퀵 이펙트)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1}) -- (2) 효과 하드 OPT 공유
	e3:SetCondition(s.tagcon_chain)
	e3:SetCost(s.tagcost)
	e3:SetTarget(s.tagtg)
	e3:SetOperation(s.tagop)
	c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- 콘택트 융합 처리 (수정됨)
--------------------------------------------------------------------------------
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_GLADIATOR_BEAST,fc,sumtype,tp)
end

-- 콘택트 융합 소재 조건: 검투수 카드군 + 덱으로 되돌릴 수 있음 + 내 필드 또는 앞면 표시
function s.contactfilter(c,tp)
	return c:IsSetCard(SET_GLADIATOR_BEAST) 
		and c:IsAbleToDeckOrExtraAsCost() 
		and (c:IsControler(tp) or c:IsFaceup())
end

function s.contactcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.contactfilter,tp,LOCATION_MZONE,0,nil,tp)
	-- [수정] CheckSubGroup 대신 단순 개수 및 소환 가능 여부 확인
	return g:GetCount()>=2 and Duel.GetLocationCountFromEx(tp,tp,g,c)>0
end

function s.contacttg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.contactfilter,tp,LOCATION_MZONE,0,nil,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	-- [수정] SelectSubGroup 대신 일반 Select 사용
	local sg=g:Select(tp,2,2,nil)
	if #sg==2 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end

function s.contactop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if not sg then return end
	Duel.ConfirmCards(1-tp,sg)
	Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_COST+REASON_MATERIAL)
	sg:DeleteGroup()
end

--------------------------------------------------------------------------------
-- (1) 덤핑 후 세트 효과
--------------------------------------------------------------------------------
function s.tgfilter(c)
	return c:IsSetCard(SET_GLADIATOR_BEAST) and c:IsMonster() and c:IsAbleToGrave()
end
function s.setfilter(c)
	return c:IsSetCard(SET_GLADIATOR_BEAST) and c:IsSpellTrap() and c:IsSSetable()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
		local g2=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)
		if #g2>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local sg=g2:Select(tp,1,1,nil)
			Duel.SSet(tp,sg)
		end
	end
end

--------------------------------------------------------------------------------
-- (2) 태그 아웃 효과 (공통)
--------------------------------------------------------------------------------
function s.tagcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeckAsCost() end
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)
end
function s.spfilter(c,e,tp)
	-- 소환 타입 113: 검투수 효과에 의한 소환 취급
	return c:IsSetCard(SET_GLADIATOR_BEAST) and c:IsMonster() 
		and c:IsCanBeSpecialSummoned(e,113,tp,false,false)
end
function s.tagtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetMZoneCount(tp,e:GetHandler())>1
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,2,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.tagop(e,tp,eg,ep,ev,re,r,rp)
	-- 59822133: 푸른 눈의 정령룡 (동시 소환 제약)
	if Duel.IsPlayerAffectedByEffect(tp,59822133) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
	if #g>=2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=g:Select(tp,2,2,nil)
		Duel.SpecialSummon(sg,113,tp,tp,false,false,POS_FACEUP)
	end
end

-- (2-1) 배틀 페이즈 종료 시 조건
function s.tagcon_bp(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetBattledGroupCount()>0
end

-- (2-2) 상대 효과 발동 시 조건
function s.tagcon_chain(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
end