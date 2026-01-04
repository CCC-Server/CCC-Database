--프레데터 플랜츠 도논 칼라미테스
--Predaplant Donon Calamites
local s,id=GetID()
function s.initial_effect(c)
	--융합 소환 및 소재 설정 ("프레데터 플랜츠" 몬스터 × 2)
	c:EnableReviveLimit()
	Fusion.AddProcFunRep(c,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_PREDAPLANT),2,true)
	
	--[효과 1] 묘지의 "융합/퓨전" 일반/속공 마법 효과 복사
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.copycost) -- 제외 코스트 처리
	e1:SetTarget(s.copytg) -- 효과 대상 및 발동 조건 복사
	e1:SetOperation(s.copyop) -- 효과 해결
	c:RegisterEffect(e1)
	
	--[효과 2] 상대에 의해 묘지로 보내졌을 경우 "프레데터 플랜츠" 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_PREDAPLANT, SET_FUSION}

--효과 1 필터: 묘지의 "융합/퓨전" 일반/속공 마법
function s.cpfilter(c)
	return c:IsSetCard(SET_FUSION) and (c:IsNormalSpell() or c:IsQuickPlaySpell())
		and c:IsAbleToRemoveAsCost() 
		and c:CheckActivateEffect(true,true,false)~=nil -- 발동 가능한 효과인지 체크
end

function s.copycost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 아나콘다처럼 2000 라이프 코스트 등을 추가하려면 여기서 처리
	if chk==0 then return Duel.IsExistingMatchingCard(s.cpfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.cpfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local te=g:GetFirst():CheckActivateEffect(true,true,false)
	e:SetLabelObject(te) -- 복사할 효과 객체 저장
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local te=e:GetLabelObject()
	if chkc then
		local tg=te:GetTarget()
		return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
	end
	if chk==0 then return true end -- cost에서 이미 존재 여부 확인됨
	
	e:SetProperty(te:GetProperty()) -- 마법 카드의 속성(대상 지정 등) 복사
	local tg=te:GetTarget()
	if tg then
		tg(e,tp,eg,ep,ev,re,r,rp,1) -- 마법 카드의 target 실행 (예: 융합 소재 선택)
	end
	Duel.ClearOperationInfo(0)
end

function s.copyop(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if not te then return end
	local op=te:GetOperation()
	if op then 
		op(e,tp,eg,ep,ev,re,r,rp) -- 마법 카드의 효과 실행
	end
	
	-- 엑스트라 덱 특수 소환 제약 (융합만 가능)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c)
	return not c:IsType(TYPE_FUSION) and c:IsLocation(LOCATION_EXTRA)
end

-- 효과 2: 유언 효과 (동일)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_FUSION) and rp==1-tp
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_PREDAPLANT) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end