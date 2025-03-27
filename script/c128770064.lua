-- U.K 원시괴조 리트라
local s, id = GetID()
function s.initial_effect(c)
	-- ① 효과: 덱에서 "U.K" 카드를 2장까지 패에 넣는다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	-- ② 효과: 릴리스되어 묘지로 보내졌을 때 추가 일반 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_RELEASE)
	e2:SetCountLimit(1,{id,1})
	e2:SetOperation(s.nsop)
	c:RegisterEffect(e2)
	-- ③ 효과: 융합 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.fuscon)
	e3:SetCost(aux.bfgcost)
	e3:SetTarget(s.fustg)
	e3:SetOperation(s.fusop)
	c:RegisterEffect(e3)
end

-- ① 효과: 코스트 설정
function s.rfilter(c,e,tp)
	return c:IsReleasable() and c~=e:GetHandler()
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 자기 자신 + 필드/패의 릴리스 가능한 몬스터 1장
		return Duel.IsExistingMatchingCard(s.rfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,e:GetHandler(),e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	-- 자기 자신과 추가 릴리스할 몬스터 선택
	local g1=Group.FromCards(e:GetHandler())
	local g2=Duel.SelectMatchingCard(tp,s.rfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,e:GetHandler(),e,tp)
	g1:Merge(g2)
	Duel.Release(g1,REASON_COST)
end

-- ① 효과: 타겟 설정
function s.thfilter(c)
	return c:IsSetCard(0x42d) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end

-- ① 효과: 실행
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,2,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

-- ② 효과: 추가 일반 소환
function s.nsop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x42d))
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-- ③ 효과: 융합 소환 조건
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsBattlePhase()
end

-- ③ 효과: 융합 소환 조건
function s.fusfilter1(c,e)
	return not c:IsImmuneToEffect(e)
end
function s.fusfilter2(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x42d) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(m,nil,chkf)
end
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		-- 아군 및 적군 필드의 융합 소재를 포함
		local mg1=Duel.GetFusionMaterial(tp):Filter(s.fusfilter1,nil,e)
		local mg2=Duel.GetMatchingGroup(s.fusfilter1,tp,0,LOCATION_MZONE,nil,e) -- 상대 필드 몬스터
		mg1:Merge(mg2)
		return Duel.IsExistingMatchingCard(s.fusfilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,chkf)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	-- 아군 및 적군 필드의 융합 소재를 포함
	local mg1=Duel.GetFusionMaterial(tp):Filter(s.fusfilter1,nil,e)
	local mg2=Duel.GetMatchingGroup(s.fusfilter1,tp,0,LOCATION_MZONE,nil,e) -- 상대 필드 몬스터
	mg1:Merge(mg2)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.fusfilter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg1,nil,chkf)
	local tc=sg:GetFirst()
	if tc then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local mat=Duel.SelectFusionMaterial(tp,tc,mg1,nil,chkf)
		tc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end
